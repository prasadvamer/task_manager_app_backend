module Authentication
  extend ActiveSupport::Concern

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed[:session_id] = {
        value: session.id,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?,
        expires: 2.weeks.from_now
      }
    end
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_id)
  end

  private

  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end
end
