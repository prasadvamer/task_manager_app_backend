# frozen_string_literal: true

module Types
  class TaskType < Types::BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :description, String, null: true
    field :status, Types::TaskStatusEnum, null: false
    field :priority, Types::TaskPriorityEnum, null: false
    field :due_date, GraphQL::Types::ISO8601DateTime, null: true
    field :completed_at, GraphQL::Types::ISO8601DateTime, null: true
    field :position, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :tags, [ Types::TagType ], null: false
    field :subtasks, [ Types::TaskType ], null: false
    field :parent, Types::TaskType, null: true

    def tags
      object.tags.order(:name)
    end

    def subtasks
      object.subtasks
    end
  end
end
