# frozen_string_literal: true

module Mutations
  class ReorderTask < BaseMutation
    description "Move a task to a new position and shift siblings"

    argument :id, ID, required: true
    argument :position, Integer, required: true

    field :tasks, [ Types::TaskType ], null: false

    def resolve(id:, position:)
      task = find_owned_task!(id)

      if position.negative?
        raise GraphQL::ExecutionError, "Position must be zero or greater"
      end

      task.reorder_to!(position)

      siblings = current_user.tasks.where(parent_id: task.parent_id).order(:position)
      { tasks: siblings }
    rescue ArgumentError => e
      raise GraphQL::ExecutionError, e.message
    end
  end
end
