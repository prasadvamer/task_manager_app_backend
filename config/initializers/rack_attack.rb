# frozen_string_literal: true

module Rack
  class Attack
    self.throttled_responder = lambda do |req|
      retry_after = (req.env["rack.attack.match_data"] || {})[:period]
      [
        429,
        { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
        [ { errors: [ { message: "Too many attempts. Please try again later." } ] }.to_json ]
      ]
    end

    def self.graphql_body(req)
      return nil unless req.post? && req.path == "/graphql"

      req.env["rack_attack.graphql_body"] ||= begin
        body = req.body.read
        req.body.rewind
        JSON.parse(body)
      rescue JSON::ParseError
        nil
      end
    end

    def self.sign_in_request?(req)
      parsed = graphql_body(req)
      return false unless parsed

      operation = (parsed["operationName"] || "").downcase
      query = (parsed["query"] || "").downcase

      operation.include?("signin") || query.match?(/mutation[^{]*\bsignin\b/)
    end

    throttle("sign_in/ip", limit: 5, period: 1.minute) do |req|
      req.ip if sign_in_request?(req)
    end

    throttle("sign_in/email", limit: 10, period: 1.hour) do |req|
      next unless sign_in_request?(req)

      parsed = graphql_body(req)
      vars = parsed&.dig("variables") || {}
      email = vars["emailAddress"] || vars["email_address"]
      email&.strip&.downcase&.presence
    end
  end
end
