# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task, type: :model do
  subject(:task) { build(:task) }

  it { is_expected.to be_valid }

  it "requires a title" do
    task.title = nil
    expect(task).not_to be_valid
  end

  it "assigns position on create" do
    user = create(:user)
    first = create(:task, user: user)
    second = create(:task, user: user)

    expect(first.position).to eq(0)
    expect(second.position).to eq(1)
  end

  it "sets completed_at when status becomes done" do
    task = create(:task, status: :todo)
    task.update!(status: :done)

    expect(task.completed_at).to be_present
  end

  it "clears completed_at when status leaves done" do
    task = create(:task, :done)
    task.update!(status: :todo)

    expect(task.completed_at).to be_nil
  end

  describe "#toggle_complete!" do
    it "marks a todo task as done" do
      task = create(:task, status: :todo)
      task.toggle_complete!

      expect(task).to be_done
    end

    it "marks a done task as todo" do
      task = create(:task, :done)
      task.toggle_complete!

      expect(task).to be_todo
    end
  end

  describe "subtasks" do
    it "allows subtasks under the same user" do
      parent = create(:task)
      subtask = create(:task, user: parent.user, parent: parent)

      expect(subtask).to be_valid
      expect(parent.subtasks).to include(subtask)
    end

    it "rejects a parent from another user" do
      subtask = build(:task, parent: create(:task))

      expect(subtask).not_to be_valid
      expect(subtask.errors[:parent]).to include("must belong to the same user")
    end

    it "destroys subtasks when parent is deleted" do
      parent = create(:task, :with_subtasks)

      expect { parent.destroy }.to change(Task, :count).by(-3)
    end
  end

  describe "#sync_tags!" do
    it "creates and assigns tags for the user" do
      task = create(:task)
      task.sync_tags!(%w[Work URGENT])

      expect(task.tags.pluck(:name)).to match_array(%w[work urgent])
    end
  end
end
