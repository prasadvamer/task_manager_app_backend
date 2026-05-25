# frozen_string_literal: true

require "rails_helper"

RSpec.describe GraphqlController, type: :request do
  let(:me_query) { "query Me { me { id } }" }

  def post_graphql(body)
    post "/graphql", params: body.to_json, headers: { "Content-Type" => "application/json" }
  end

  describe "prepare_variables" do
    context "when variables is omitted from the body" do
      it "treats it as an empty hash and executes successfully" do
        post_graphql(query: me_query, operationName: "Me")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when variables is a JSON string" do
      it "parses the string and executes successfully" do
        post_graphql(query: me_query, variables: "{}", operationName: "Me")
        expect(response).to have_http_status(:ok)
      end

      it "treats a blank string as an empty hash" do
        post_graphql(query: me_query, variables: "", operationName: "Me")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when variables is an unexpected type" do
      it "returns a 500 error" do
        post_graphql(query: me_query, variables: [1, 2, 3], operationName: "Me")
        expect(response).to have_http_status(500)
      end
    end
  end
end
