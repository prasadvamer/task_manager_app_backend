# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  it "destroys task associations when deleted" do
    task = create(:task, :with_tags)

    expect { task.tags.first.destroy }.to change(TaskTag, :count).by(-1)
  end
end
