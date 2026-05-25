# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack sign_in throttling", type: :request do
  let(:sign_in_query) do
    <<~GQL
      mutation SignIn($emailAddress: String!, $password: String!) {
        signIn(input: { emailAddress: $emailAddress, password: $password }) {
          user { id }
        }
      }
    GQL
  end

  let(:sign_out_query) do
    <<~GQL
      mutation SignOut {
        signOut(input: {}) { success }
      }
    GQL
  end

  def graphql_post(query:, variables: {}, operation_name: nil, ip: "1.2.3.4")
    post "/graphql",
      params: { query: query, variables: variables, operationName: operation_name }.to_json,
      headers: { "Content-Type" => "application/json" },
      env: { "REMOTE_ADDR" => ip }
  end

  def sign_in(email: "user@example.com", password: "password12345", ip: "1.2.3.4")
    graphql_post(
      query: sign_in_query,
      variables: { emailAddress: email, password: password },
      operation_name: "SignIn",
      ip: ip
    )
  end

  before do
    host! "localhost"
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.cache.store.clear
    Rack::Attack.enabled = false
  end

  describe "IP throttle" do
    it "allows the first 5 attempts" do
      5.times { sign_in(ip: "1.2.3.4") }
      expect(response.status).not_to eq(429)
    end

    it "blocks the 6th attempt from the same IP" do
      6.times { sign_in(ip: "1.2.3.4") }
      expect(response.status).to eq(429)
    end

    it "tracks IPs independently" do
      5.times { sign_in(ip: "1.2.3.4") }
      sign_in(ip: "9.9.9.9")
      expect(response.status).not_to eq(429)
    end
  end

  describe "email throttle" do
    it "blocks the 11th attempt for the same email across different IPs" do
      10.times { |i| sign_in(ip: "10.0.0.#{i + 1}") }
      sign_in(ip: "10.0.0.11")
      expect(response.status).to eq(429)
    end

    it "tracks emails independently" do
      10.times { |i| sign_in(email: "a@example.com", ip: "10.0.0.#{i + 1}") }
      sign_in(email: "b@example.com", ip: "10.0.0.11")
      expect(response.status).not_to eq(429)
    end
  end

  describe "throttled response" do
    before { 6.times { sign_in(ip: "1.2.3.4") } }

    it "returns 429 with a GraphQL error body" do
      body = JSON.parse(response.body)
      expect(body["errors"].first["message"]).to eq("Too many attempts. Please try again later.")
    end

    it "includes a Retry-After header" do
      expect(response.headers["Retry-After"]).to be_present
    end
  end

  describe "non-signIn mutations" do
    it "are not throttled when signIn limit is exhausted" do
      6.times { sign_in(ip: "1.2.3.4") }
      graphql_post(query: sign_out_query, operation_name: "SignOut", ip: "1.2.3.4")
      expect(response.status).not_to eq(429)
    end
  end
end
