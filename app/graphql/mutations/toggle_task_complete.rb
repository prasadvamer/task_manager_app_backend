# frozen_string_literal: true

module Mutations
  class ToggleTaskComplete < BaseMutation
    description "Toggle a task between todo and done"

    argument :id, ID, required: true

    field :task, Types::TaskType, null: true

    def resolve(id:)
      task = find_owned_task!(id)
      task.toggle_complete!

      { task: task.reload }
    end
  end
end
