require 'net/http'
require 'uri'

class Oauth::OauthController < Devise::OmniauthCallbacksController
  def callback
    # https://sandbox.bluesquare.org/uaa/oauth/authorize?client_id=[client_id]&response_type=code
    program = Program.find(params["program_id"]) rescue nil

    if program.nil?
      flash[:failure] = "Log-in failed: program with ID #{params["program_id"]} does not exist"
      redirect_to("/users/sign_in")
      return
    end
    
    url_post = program.project_anchor.project.dhis2_url + "/uaa/oauth/token"
    
    uri = URI.parse(url_post)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(program.oauth_client_id, program.oauth_client_secret)
    request["Accept"] = "application/json"
    request.set_form_data(
      "code" => params["code"],
      "grant_type" => "authorization_code"
    )
    req_options = {
      use_ssl: uri.scheme == "https"
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.code != "200"
      flash[:failure] = "Log-in failed: invalid code provided to DHIS2 authorization"
      redirect_to("/users/sign_in")
      return
    end

    access_token = JSON.parse(response.body)["access_token"] rescue nil

    if access_token.nil?
      flash[:failure] = "Log-in failed: bad response from DHIS2, please check the logs"
      redirect_to("/users/sign_in")
      return
    end

    user_info = RestClient.get(program.project_anchor.project.dhis2_url + "/api/me", { "Authorization": "Bearer #{access_token}" })

    user_info = JSON.parse(user_info) rescue nil

    if user_info.nil?
      flash[:failure] = "Log-in failed: bad response from DHIS2, please check the logs"
      redirect_to("/users/sign_in")
      return
    end

    dhis2_user_ref = user_info["id"]

    user = program.users.find_by_dhis2_user_ref(dhis2_user_ref)
    
    if user
      sign_in_and_redirect(user)
    else  
      flash[:failure] = "Log-in failed: user not found in DHIS2"
      redirect_to("/users/sign_in")
      return
    end
  end
end