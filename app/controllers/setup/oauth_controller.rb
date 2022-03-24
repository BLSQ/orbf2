# frozen_string_literal: true

class Setup::OauthController < PrivateController
  def create
    if current_program.oauth_client_id && current_program.oauth_client_secret
      flash[:success] = "DHIS2 log-in already enabled for #{current_project.name}"
      redirect_to setup_project_path(current_project)
      return
    end

    current_project.enable_oauth
    flash[:success] = "DHIS2 log-in enabled for #{current_project.name}"
    redirect_to setup_project_path(current_project)
  
  rescue StandardError => e
    flash[:failure] = "An error occured during set-up for DHIS2 log-in: #{e.class.name} #{e.message[0..100]}"
    redirect_to setup_project_path(current_project)
  end
end