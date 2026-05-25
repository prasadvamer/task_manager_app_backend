# frozen_string_literal: true

require "rails_helper"

RSpec.describe "signUp mutation", type: :request do
  let(:query) do
    <<~GQL
      mutation SignUp($emailAddress: String!, $password: String!, $passwordConfirmation: String!) {
        signUp(input: { emailAddress: $emailAddress, password: $password, passwordConfirmation: $passwordConfirmation }) {
          user { id emailAddress }
        }
      }
    GQL
  end

  def sign_up(email: "new@example.com", password: "secure_password_123", confirmation: nil)
    graphql_post(
      query: query,
      variables: {
        emailAddress: email,
        password: password,
        passwordConfirmation: confirmation || password
      },
      operation_name: "SignUp"
    )
  end

  context "with valid attributes" do
    before { sign_up }

    it "returns the new user" do
      expect(graphql_data.dig("signUp", "user", "emailAddress")).to eq("new@example.com")
    end

    it "creates the user record" do
      expect(User.find_by(email_address: "new@example.com")).to be_present
    end

    it "sets a session cookie" do
      expect(response.cookies["session_id"]).to be_present
    end
  end

  context "with mismatched password confirmation" do
    before { sign_up(confirmation: "different_password_456") }

    it "returns a validation error" do
      expect(graphql_errors.first["message"]).to be_present
    end

    it "does not return a user" do
      expect(graphql_data.dig("signUp", "user")).to be_nil
    end
  end

  context "with a password that is too short" do
    before { sign_up(password: "short", confirmation: "short") }

    it "returns a validation error mentioning password" do
      expect(graphql_errors.first["message"]).to include("Password")
    end
  end

  context "with an invalid email format" do
    before { sign_up(email: "not-an-email") }

    it "returns a validation error" do
      expect(graphql_errors.first["message"]).to be_present
    end
  end

  context "with a duplicate email" do
    before do
      create(:user, email_address: "taken@example.com")
      sign_up(email: "taken@example.com")
    end

    it "returns a validation error" do
      expect(graphql_errors.first["message"]).to be_present
    end
  end
end
