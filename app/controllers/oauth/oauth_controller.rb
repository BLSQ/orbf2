require 'net/http'
require 'uri'

class Oauth::OauthController < Devise::OmniauthCallbacksController
  def callback
    # https://sandbox.bluesquare.org/uaa/oauth/authorize?client_id=[client_id]&response_type=code

    program = Program.find(params["program_id"])
    url_post = program.project_anchor.project.dhis2_url + "/uaa/oauth/token"
    
    uri = URI.parse(url_post)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(program.oauth_client_id, program.oauth_client_secret)
    request["Accept"] = "application/json"
    request.set_form_data(
      "code" => params["code"],
      "grant_type" => "authorization_code",
    )
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    access_token = JSON.parse(response.body)["access_token"]
    user_info = RestClient.get(program.project_anchor.project.dhis2_url + "/api/me", { "Authorization": "Bearer #{access_token}" })
    user_info = JSON.parse(user_info)
    user_dhis2_id = user_info["userCredentials"]["id"]
    
    user = User.find_by_dhis2_user_ref(user_dhis2_id)
    unless user.nil?
      sign_in_and_redirect(user)
    end
  end
end

# payload = {
#   "code": params["code"],
#   "grant_type": "authorization_code",
#   "redirect_uri": "",
#   "client_id": program.oauth_client_id,
# }

# url = URI.parse(url).tap do |url|
#   url.user     = CGI.escape(program.oauth_client_id)
#   url.password = CGI.escape(program.oauth_client_secret)
# end.to_s

# byebug
# response = RestClient.post(url, payload.to_json, { content_type: :json, accept: :json })