# A constraint to check if a request has access to our developer tools.
class CanAccessDeveloperToolsConstraint
  def self.matches?(request)
    if ActionController::HttpAuthentication::Basic.has_basic_credentials?(request)
      credentials = ActionController::HttpAuthentication::Basic.decode_credentials(request)
      email, password = credentials.split(':')
      email == "admin" && password == ENV["ADMIN_PASSWORD"]
    else
      user_id = request.session.fetch("warden.user.user.key", []).flatten.first
      if user_id && user = User.find(user_id)
        Scorpio.is_developer?(user)
      else
        false
      end
    end
  end
end
