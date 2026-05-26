class TaskTag < ApplicationRecord
  belongs_to :task
  belongs_to :tag

  validate :task_and_tag_belong_to_same_user

  private

  def task_and_tag_belong_to_same_user
    return if task.nil? || tag.nil?

    if task.user_id != tag.user_id
      errors.add(:tag, "must belong to the same user as the task")
    end
  end
end
