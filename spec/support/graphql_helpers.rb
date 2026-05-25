# frozen_string_literal: true

module GraphqlHelpers
  def graphql_post(query:, variables: {}, operation_name: nil)
    post "/graphql",
      params: { query: query, variables: variables, operationName: operation_name }.to_json,
      headers: { "Content-Type" => "application/json" }
  end

  def graphql_data
    JSON.parse(response.body)["data"]
  end

  def graphql_errors
    JSON.parse(response.body)["errors"]
  end
end
