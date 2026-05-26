# frozen_string_literal: true

module Types
  class TaskStatusEnum < Types::BaseEnum
    value "TODO", "Not started", value: "todo"
    value "IN_PROGRESS", "In progress", value: "in_progress"
    value "DONE", "Completed", value: "done"
  end
end
