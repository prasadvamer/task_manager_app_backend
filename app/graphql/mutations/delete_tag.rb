# frozen_string_literal: true

module Mutations
  class DeleteTag < BaseMutation
    description "Delete a tag and remove it from all tasks"

    argument :id, ID, required: true

    field :success, Boolean, null: false

    def resolve(id:)
      tag = find_owned_tag!(id)
      tag.destroy!

      { success: true }
    end
  end
end
