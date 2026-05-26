# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    field :me, Types::UserType, null: true,
      description: "Returns the currently authenticated user"

    def me
      context[:current_user]
    end

    field :tasks, [ Types::TaskType ], null: false,
      description: "List top-level tasks for the current user" do
      argument :status, Types::TaskStatusEnum, required: false
      argument :priority, Types::TaskPriorityEnum, required: false
      argument :tag_id, ID, required: false
    end

    def tasks(status: nil, priority: nil, tag_id: nil)
      raise GraphQL::ExecutionError, "Authentication required" unless context[:current_user]

      scope = context[:current_user].tasks.top_level.order(:position)
      scope = scope.where(status: status) if status
      scope = scope.where(priority: priority) if priority
      scope = scope.joins(:tags).where(tags: { id: tag_id }) if tag_id

      scope.distinct
    end

    field :task, Types::TaskType, null: true,
      description: "Fetch a single task by ID" do
      argument :id, ID, required: true
    end

    def task(id:)
      raise GraphQL::ExecutionError, "Authentication required" unless context[:current_user]

      context[:current_user].tasks.find_by(id: id)
    end

    field :tags, [ Types::TagType ], null: false,
      description: "List tags for the current user"

    def tags
      raise GraphQL::ExecutionError, "Authentication required" unless context[:current_user]

      context[:current_user].tags.order(:name)
    end
  end
end
