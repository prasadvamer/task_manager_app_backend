# frozen_string_literal: true

require "rails_helper"

RSpec.describe "deleteTag mutation", type: :request do
  let!(:user) { create(:user) }
  let!(:task) { create(:task, user: user).tap { |record| record.sync_tags!(%w[work]) } }
  let!(:tag) { task.tags.sole }

  before { sign_in_as(user) }

  let(:mutation) do
    <<~GQL
      mutation DeleteTag($id: ID!) {
        deleteTag(input: { id: $id }) { success }
      }
    GQL
  end

  it "deletes the tag" do
    expect {
      graphql_post(query: mutation, variables: { id: tag.id.to_s }, operation_name: "DeleteTag")
    }.to change(Tag, :count).by(-1)

    expect(graphql_data.dig("deleteTag", "success")).to be(true)
  end

  it "removes the tag from tasks" do
    graphql_post(query: mutation, variables: { id: tag.id.to_s }, operation_name: "DeleteTag")

    expect(task.reload.tags).to be_empty
  end

  it "removes orphaned tags from the tags query" do
    graphql_post(query: mutation, variables: { id: tag.id.to_s }, operation_name: "DeleteTag")

    graphql_post(query: "query { tags { id } }")

    expect(graphql_data.fetch("tags")).to be_empty
  end

  context "when the tag belongs to another user" do
    let!(:other_tag) { create(:tag) }

    before { graphql_post(query: mutation, variables: { id: other_tag.id.to_s }, operation_name: "DeleteTag") }

    it "returns an error" do
      expect(graphql_errors.first["message"]).to eq("Tag not found")
    end
  end
end
