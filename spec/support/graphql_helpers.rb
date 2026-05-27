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

  def sign_in_as(user, password: "password12345")
    graphql_post(
      query: <<~GQL,
        mutation SignIn($emailAddress: String!, $password: String!) {
          signIn(input: { emailAddress: $emailAddress, password: $password }) {
            user { id }
          }
        }
      GQL
      variables: { emailAddress: user.email_address, password: password },
      operation_name: "SignIn"
    )
  end
end
