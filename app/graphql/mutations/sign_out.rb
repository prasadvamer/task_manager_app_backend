# frozen_string_literal: true

module Mutations
  class SignOut < BaseMutation
    description "Sign out the current user"

    field :success, Boolean, null: false

    def resolve
      controller.terminate_session
      { success: true }
    end
  end
end
