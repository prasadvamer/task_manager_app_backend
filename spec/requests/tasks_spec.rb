# frozen_string_literal: true

require "rails_helper"

RSpec.describe "tasks API", type: :request do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }

  describe "tasks query" do
    before { sign_in_as(user) }

    let!(:task) { create(:task, user: user, title: "My task") }
    let!(:subtask) { create(:task, user: user, parent: task, title: "Subtask") }
    let!(:other_task) { create(:task, user: other_user, title: "Other task") }

    let(:query) do
      <<~GQL
        query Tasks {
          tasks { id title subtasks { id title } }
        }
      GQL
    end

    before { graphql_post(query: query, operation_name: "Tasks") }

    it "returns top-level tasks for the current user" do
      titles = graphql_data.fetch("tasks").map { |t| t["title"] }
      expect(titles).to eq([ "My task" ])
    end

    it "includes subtasks on the task query" do
      task_query = <<~GQL
        query Task($id: ID!) {
          task(id: $id) { id title subtasks { title } }
        }
      GQL

      graphql_post(query: task_query, variables: { id: task.id.to_s }, operation_name: "Task")

      expect(graphql_data.dig("task", "subtasks", 0, "title")).to eq("Subtask")
    end
  end

  describe "createTask mutation" do
    before { sign_in_as(user) }

    let(:mutation) do
      <<~GQL
        mutation CreateTask($title: String!, $tagNames: [String!]) {
          createTask(input: { title: $title, tagNames: $tagNames }) {
            task { id title status tags { name } }
          }
        }
      GQL
    end

    it "creates a task" do
      graphql_post(query: mutation, variables: { title: "New task", tagNames: [ "work" ] }, operation_name: "CreateTask")

      expect(graphql_data.dig("createTask", "task", "title")).to eq("New task")
      expect(graphql_data.dig("createTask", "task", "status")).to eq("TODO")
      expect(graphql_data.dig("createTask", "task", "tags", 0, "name")).to eq("work")
    end

    it "creates a subtask when parentId is provided" do
      parent = create(:task, user: user)
      mutation = <<~GQL
        mutation CreateTask($title: String!, $parentId: ID!) {
          createTask(input: { title: $title, parentId: $parentId }) {
            task { id title parent { id } }
          }
        }
      GQL

      graphql_post(query: mutation, variables: { title: "Child task", parentId: parent.id.to_s }, operation_name: "CreateTask")

      expect(graphql_data.dig("createTask", "task", "parent", "id")).to eq(parent.id.to_s)
    end
  end

  describe "updateTask mutation" do
    before { sign_in_as(user) }

    let!(:task) { create(:task, user: user, title: "Old title") }

    it "updates the task" do
      mutation = <<~GQL
        mutation UpdateTask($id: ID!, $title: String!, $status: TaskStatusEnum) {
          updateTask(input: { id: $id, title: $title, status: $status }) {
            task { title status }
          }
        }
      GQL

      graphql_post(
        query: mutation,
        variables: { id: task.id.to_s, title: "Updated title", status: "IN_PROGRESS" },
        operation_name: "UpdateTask"
      )

      expect(graphql_data.dig("updateTask", "task", "title")).to eq("Updated title")
      expect(graphql_data.dig("updateTask", "task", "status")).to eq("IN_PROGRESS")
    end
  end

  describe "toggleTaskComplete mutation" do
    before { sign_in_as(user) }

    let!(:task) { create(:task, user: user, status: :todo) }

    it "marks the task as done" do
      mutation = <<~GQL
        mutation ToggleTaskComplete($id: ID!) {
          toggleTaskComplete(input: { id: $id }) {
            task { status completedAt }
          }
        }
      GQL

      graphql_post(query: mutation, variables: { id: task.id.to_s }, operation_name: "ToggleTaskComplete")

      expect(graphql_data.dig("toggleTaskComplete", "task", "status")).to eq("DONE")
      expect(graphql_data.dig("toggleTaskComplete", "task", "completedAt")).to be_present
    end
  end

  describe "deleteTask mutation" do
    before { sign_in_as(user) }

    let!(:task) { create(:task, :with_subtasks, user: user) }

    it "deletes the task and subtasks" do
      mutation = <<~GQL
        mutation DeleteTask($id: ID!) {
          deleteTask(input: { id: $id }) { success }
        }
      GQL

      expect {
        graphql_post(query: mutation, variables: { id: task.id.to_s }, operation_name: "DeleteTask")
      }.to change(Task, :count).by(-3)

      expect(graphql_data.dig("deleteTask", "success")).to be(true)
    end
  end

  describe "reorderTask mutation" do
    before { sign_in_as(user) }

    let!(:first) { create(:task, user: user, title: "First") }
    let!(:second) { create(:task, user: user, title: "Second") }
    let!(:third) { create(:task, user: user, title: "Third") }

    it "reorders tasks and returns the updated sibling list" do
      mutation = <<~GQL
        mutation ReorderTask($id: ID!, $position: Int!) {
          reorderTask(input: { id: $id, position: $position }) {
            tasks { id title position }
          }
        }
      GQL

      graphql_post(
        query: mutation,
        variables: { id: second.id.to_s, position: 2 },
        operation_name: "ReorderTask"
      )

      titles = graphql_data.fetch("reorderTask").fetch("tasks").map { |task| task["title"] }
      positions = graphql_data.fetch("reorderTask").fetch("tasks").map { |task| task["position"] }

      expect(titles).to eq([ "First", "Third", "Second" ])
      expect(positions).to eq([ 0, 1, 2 ])
    end
  end

  context "when not authenticated" do
    it "returns an authentication error for tasks query" do
      graphql_post(query: "query { tasks { id } }")

      expect(graphql_errors.first["message"]).to eq("Authentication required")
    end
  end
end
