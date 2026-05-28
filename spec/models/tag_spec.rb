# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  it "destroys task associations when deleted" do
    task = create(:task, :with_tags)

    expect { task.tags.first.destroy }.to change(TaskTag, :count).by(-1)
  end

  describe ".cleanup_orphans_for" do
    it "removes tags with no task associations" do
      user = create(:user)
      task = create(:task, user: user)
      task.sync_tags!(%w[work])
      orphan = create(:tag, user: user, name: "orphan")

      described_class.cleanup_orphans_for(user)

      expect(described_class.exists?(orphan.id)).to be(false)
      expect(user.tags.pluck(:name)).to eq([ "work" ])
    end
  end
end
