class Task < ApplicationRecord
  belongs_to :user
  belongs_to :parent, class_name: "Task", optional: true
  has_many :subtasks, -> { order(:position) }, class_name: "Task", foreign_key: "parent_id", dependent: :destroy, inverse_of: :parent

  enum :status, { todo: "todo", in_progress: "in_progress", done: "done" }, default: :todo
  enum :priority, { low: "low", medium: "medium", high: "high" }, default: :medium

  validates :title, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :parent_belongs_to_same_user
  validate :parent_cannot_be_self

  before_validation :assign_position, on: :create
  before_save :sync_completed_at

  scope :top_level, -> { where(parent_id: nil) }

  def toggle_complete!
    if done?
      update!(status: :todo)
    else
      update!(status: :done)
    end
  end

  private

  def assign_position
    siblings = user.tasks.where(parent_id: parent_id)
    self.position = (siblings.maximum(:position) || -1) + 1
  end

  def sync_completed_at
    if done?
      self.completed_at ||= Time.current
    else
      self.completed_at = nil
    end
  end

  def parent_belongs_to_same_user
    return if parent.nil?

    if parent.user_id != user_id
      errors.add(:parent, "must belong to the same user")
    end
  end

  def parent_cannot_be_self
    return if parent_id.nil?

    if parent_id == id
      errors.add(:parent, "cannot be the task itself")
    end
  end
end
