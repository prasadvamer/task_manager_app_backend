# frozen_string_literal: true

require "rails_helper"

RSpec.describe "signIn mutation", type: :request do
  let(:query) do
    <<~GQL
      mutation SignIn($emailAddress: String!, $password: String!) {
        signIn(input: { emailAddress: $emailAddress, password: $password }) {
          user { id emailAddress }
        }
      }
    GQL
  end

  let(:password) { "correct_password_123" }
  let!(:user) { create(:user, password: password) }

  context "with valid credentials" do
    before { graphql_post(query: query, variables: { emailAddress: user.email_address, password: password }, operation_name: "SignIn") }

    it "returns the user" do
      expect(graphql_data.dig("signIn", "user", "emailAddress")).to eq(user.email_address)
    end

    it "sets a session cookie" do
      expect(response.cookies["session_id"]).to be_present
    end

    it "creates a session record" do
      expect(user.sessions.count).to eq(1)
    end
  end

  context "with wrong password" do
    before { graphql_post(query: query, variables: { emailAddress: user.email_address, password: "wrong" }, operation_name: "SignIn") }

    it "returns an error" do
      expect(graphql_errors.first["message"]).to eq("Invalid email or password")
    end

    it "does not set a session cookie" do
      expect(response.cookies["session_id"]).to be_nil
    end
  end

  context "with unknown email" do
    before { graphql_post(query: query, variables: { emailAddress: "no@one.com", password: "anything" }, operation_name: "SignIn") }

    it "returns the same error message" do
      expect(graphql_errors.first["message"]).to eq("Invalid email or password")
    end
  end
end
