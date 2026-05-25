# frozen_string_literal: true

module Mutations
  class SignIn < BaseMutation
    description "Sign in with email and password"

    argument :email_address, String, required: true
    argument :password, String, required: true

    field :user, Types::UserType, null: true

    def resolve(email_address:, password:)
      user = User.authenticate_by(email_address: email_address, password: password)
      # TODO: rate limit failed attempts
      raise GraphQL::ExecutionError, "Incorrect email or password" unless user

      controller.start_new_session_for(user)
      { user: user }
    end
  end
end
