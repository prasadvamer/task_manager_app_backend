# frozen_string_literal: true

module Mutations
  class SignUp < BaseMutation
    description "Create a new account and sign in"

    argument :email_address, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true

    field :user, Types::UserType, null: true

    def resolve(email_address:, password:, password_confirmation:)
      user = User.new(
        email_address: email_address,
        password: password,
        password_confirmation: password_confirmation
      )

      unless user.save
        raise GraphQL::ExecutionError, user.errors.full_messages.join(", ")
      end

      controller.start_new_session_for(user)
      { user: user }
    end
  end
end
