# frozen_string_literal: true

module Mutations
  class UpdateTask < BaseMutation
    description "Update a task"

    argument :id, ID, required: true
    argument :title, String, required: false
    argument :description, String, required: false
    argument :due_date, GraphQL::Types::ISO8601DateTime, required: false
    argument :priority, Types::TaskPriorityEnum, required: false
    argument :status, Types::TaskStatusEnum, required: false
    argument :position, Integer, required: false
    argument :tag_names, [ String ], required: false

    field :task, Types::TaskType, null: true

    def resolve(id:, **attributes)
      task = find_owned_task!(id)
      tag_names = attributes.delete(:tag_names)

      unless task.update(attributes.compact)
        raise GraphQL::ExecutionError, task.errors.full_messages.join(", ")
      end

      task.sync_tags!(tag_names) unless tag_names.nil?

      { task: task.reload }
    end
  end
end
