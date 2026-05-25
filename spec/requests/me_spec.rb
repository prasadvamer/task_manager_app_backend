# frozen_string_literal: true

require "rails_helper"

RSpec.describe "me query", type: :request do
  let(:me_query) do
    <<~GQL
      query Me {
        me { id emailAddress }
      }
    GQL
  end

  let(:sign_in_query) do
    <<~GQL
      mutation SignIn($emailAddress: String!, $password: String!) {
        signIn(input: { emailAddress: $emailAddress, password: $password }) {
          user { id }
        }
      }
    GQL
  end

  context "when authenticated" do
    let!(:user) { create(:user) }

    before do
      graphql_post(query: sign_in_query, variables: { emailAddress: user.email_address, password: "password12345" }, operation_name: "SignIn")
      graphql_post(query: me_query, operation_name: "Me")
    end

    it "returns the current user" do
      expect(graphql_data.dig("me", "emailAddress")).to eq(user.email_address)
    end
  end

  context "when not authenticated" do
    before { graphql_post(query: me_query, operation_name: "Me") }

    it "returns nil" do
      expect(graphql_data["me"]).to be_nil
    end
  end
end
