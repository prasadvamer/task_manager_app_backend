# frozen_string_literal: true

module Mutations
  class DeleteTask < BaseMutation
    description "Delete a task and its subtasks"

    argument :id, ID, required: true

    field :success, Boolean, null: false

    def resolve(id:)
      task = find_owned_task!(id)
      task.destroy!

      { success: true }
    end
  end
end
