class Tag < ApplicationRecord
  belongs_to :user
  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags

  normalizes :name, with: ->(name) { name.strip.downcase }

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }

  def self.cleanup_orphans_for(user)
    user.tags.where.missing(:task_tags).destroy_all
  end
end
