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

    it "cleans up orphaned tags when the task is deleted" do
      task = create(:task)
      task.sync_tags!(%w[work])

      expect { task.destroy }.to change(Tag, :count).by(-1)
    end
  end

  describe "#sync_tags!" do
    it "creates and assigns tags for the user" do
      task = create(:task)
      task.sync_tags!(%w[Work URGENT])

      expect(task.tags.pluck(:name)).to match_array(%w[work urgent])
    end

    it "removes orphaned tags when they are no longer assigned" do
      task = create(:task)
      task.sync_tags!(%w[work urgent])
      urgent = task.tags.find_by!(name: "urgent")

      task.sync_tags!(%w[work])

      expect(Tag.exists?(urgent.id)).to be(false)
      expect(task.reload.tags.pluck(:name)).to eq([ "work" ])
    end

    it "keeps tags that are still assigned to other tasks" do
      user = create(:user)
      first = create(:task, user: user)
      second = create(:task, user: user)
      first.sync_tags!(%w[shared personal])
      second.sync_tags!(%w[shared])

      first.sync_tags!(%w[personal])

      expect(user.tags.pluck(:name)).to match_array(%w[personal shared])
    end
  end

  describe "#reorder_to!" do
    it "moves a task down and shifts siblings up" do
      user = create(:user)
      first = create(:task, user: user, title: "First")
      second = create(:task, user: user, title: "Second")
      third = create(:task, user: user, title: "Third")

      second.reorder_to!(2)

      expect(first.reload.position).to eq(0)
      expect(third.reload.position).to eq(1)
      expect(second.reload.position).to eq(2)
    end

    it "moves a task up and shifts siblings down" do
      user = create(:user)
      first = create(:task, user: user, title: "First")
      second = create(:task, user: user, title: "Second")
      third = create(:task, user: user, title: "Third")

      third.reorder_to!(0)

      expect(third.reload.position).to eq(0)
      expect(first.reload.position).to eq(1)
      expect(second.reload.position).to eq(2)
    end

    it "reorders within subtasks independently of top-level tasks" do
      user = create(:user)
      parent = create(:task, user: user, title: "Parent")
      subtask_a = create(:task, user: user, parent: parent, title: "Subtask A")
      subtask_b = create(:task, user: user, parent: parent, title: "Subtask B")

      subtask_b.reorder_to!(0)

      expect(subtask_b.reload.position).to eq(0)
      expect(subtask_a.reload.position).to eq(1)
      expect(parent.reload.position).to eq(0)
    end
  end
end
