require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires email_address" do
      user.email_address = nil
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("can't be blank")
    end

    it "rejects malformed email" do
      user.email_address = "not-an-email"
      expect(user).not_to be_valid
    end

    it "requires unique email (case-insensitive)" do
      create(:user, email_address: "dupe@example.com")
      user.email_address = "DUPE@example.com"
      expect(user).not_to be_valid
    end

    it "rejects passwords shorter than 12 characters" do
      user.password = "short"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "accepts passwords of 12 or more characters" do
      user.password = "a" * 12
      expect(user).to be_valid
    end
  end

  describe "email normalisation" do
    it "strips whitespace and downcases on save" do
      user = create(:user, email_address: "  Admin@Example.COM  ")
      expect(user.reload.email_address).to eq("admin@example.com")
    end
  end

  describe "authentication" do
    it "authenticates with correct password" do
      persisted = create(:user, password: "correct_password_123")
      expect(User.authenticate_by(email_address: persisted.email_address, password: "correct_password_123")).to eq(persisted)
    end

    it "returns nil for wrong password" do
      persisted = create(:user)
      expect(User.authenticate_by(email_address: persisted.email_address, password: "wrong")).to be_nil
    end
  end

  describe "sessions" do
    it "destroys dependent sessions when user is deleted" do
      persisted = create(:user)
      persisted.sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec")
      expect { persisted.destroy }.to change(Session, :count).by(-1)
    end
  end
end
