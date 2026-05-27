# frozen_string_literal: true

module Mutations
  class CreateTask < BaseMutation
    description "Create a task or subtask"

    argument :title, String, required: true
    argument :description, String, required: false
    argument :due_date, GraphQL::Types::ISO8601DateTime, required: false
    argument :priority, Types::TaskPriorityEnum, required: false
    argument :status, Types::TaskStatusEnum, required: false
    argument :parent_id, ID, required: false
    argument :tag_names, [ String ], required: false

    field :task, Types::TaskType, null: true

    def resolve(title:, description: nil, due_date: nil, priority: nil, status: nil, parent_id: nil, tag_names: nil)
      require_authentication!

      parent = find_owned_parent!(parent_id) if parent_id.present?

      attributes = { title: title, parent: parent }
      attributes[:description] = description unless description.nil?
      attributes[:due_date] = due_date unless due_date.nil?
      attributes[:priority] = priority unless priority.nil?
      attributes[:status] = status unless status.nil?

      task = current_user.tasks.build(attributes)

      unless task.save
        raise GraphQL::ExecutionError, task.errors.full_messages.join(", ")
      end

      task.sync_tags!(tag_names) if tag_names.present?

      { task: task.reload }
    end
  end
end
