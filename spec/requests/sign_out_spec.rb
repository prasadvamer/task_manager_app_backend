# frozen_string_literal: true

require "rails_helper"

RSpec.describe "signOut mutation", type: :request do
  let(:sign_out_query) do
    <<~GQL
      mutation SignOut {
        signOut(input: {}) { success }
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
      graphql_post(query: sign_out_query, operation_name: "SignOut")
    end

    it "returns success" do
      expect(graphql_data.dig("signOut", "success")).to be true
    end

    it "destroys the session record" do
      expect(user.sessions.count).to eq(0)
    end

    it "clears the session cookie" do
      expect(response.cookies["session_id"]).to be_nil
    end
  end

  context "when not authenticated" do
    before { graphql_post(query: sign_out_query, operation_name: "SignOut") }

    it "returns success without error" do
      expect(graphql_errors).to be_nil
      expect(graphql_data.dig("signOut", "success")).to be true
    end
  end
end
