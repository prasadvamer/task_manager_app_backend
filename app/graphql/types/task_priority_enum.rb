# frozen_string_literal: true

module Types
  class TaskPriorityEnum < Types::BaseEnum
    value "LOW", "Low priority", value: "low"
    value "MEDIUM", "Medium priority", value: "medium"
    value "HIGH", "High priority", value: "high"
  end
end
