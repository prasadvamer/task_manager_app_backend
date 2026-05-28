# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    private

    def current_user
      context[:current_user]
    end

    def controller
      context[:controller]
    end

    def require_authentication!
      raise GraphQL::ExecutionError, "Authentication required" unless current_user
    end

    def find_owned_task!(id)
      require_authentication!
      task = current_user.tasks.find_by(id: id)
      raise GraphQL::ExecutionError, "Task not found" unless task

      task
    end

    def find_owned_parent!(parent_id)
      parent = current_user.tasks.find_by(id: parent_id)
      raise GraphQL::ExecutionError, "Parent task not found" unless parent

      parent
    end

    def find_owned_tag!(id)
      require_authentication!
      tag = current_user.tags.find_by(id: id)
      raise GraphQL::ExecutionError, "Tag not found" unless tag

      tag
    end
  end
end
