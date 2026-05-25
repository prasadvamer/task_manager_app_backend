# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }
  let(:session) { user.sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec") }

  context "with a valid session" do
    it "connects and identifies the current user" do
      allow(Session).to receive(:find_by).and_return(session)
      connect
      expect(connection.current_user).to eq(user)
    end
  end

  context "without a valid session" do
    it "rejects the connection" do
      expect { connect }.to have_rejected_connection
    end
  end
end
