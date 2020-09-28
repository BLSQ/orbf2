# frozen_string_literal: true

namespace :ui do

  desc "Setup the token and url for hesabu ui manager for a given project_anchor_id"
  task :setup, [:project_anchor_id] => [:environment] do |_task, args|
    project_anchors = ProjectAnchor.all.where(id: args[:project_anchor_id])
    project_anchors.find_each do |project_anchor|
      setup_token(project_anchor)
    end
  end

  desc "Setup the token and url for hesabu ui manager for all projects"
  task :setup_all, [:project_anchor_id] => [:environment] do |_task, _args|
    ProjectAnchor.find_each do |project_anchor|
      setup_token(project_anchor)
    end
  end


  desc "Deploy hesabu ui manager for a given project_anchor_id"
  task :deploy, [:project_anchor_id] => [:environment] do |_task, args|
    download_latest_build
    project_anchors = ProjectAnchor.all.where(id: args[:project_anchor_id])
    project_anchors.find_each do |project_anchor|
      deploy_dhis2_app(project_anchor)
    end
  end

  desc "Deploy hesabu ui manager for all projects"
  task :deploy_all, [:project_anchor_id] => [:environment] do |_task, _args|
    download_latest_build
    ProjectAnchor.find_each do |project_anchor|
      deploy_dhis2_app(project_anchor)
    end
  end

  TARGET_FILE_NAME = "/tmp/Hesabu.zip"

  def log_info(message)
    puts message
  end

  def setup_token(project_anchor)
    unless project_anchor.token
      log_info "INFO skipping no token for #{project_anchor.project.name} (project_anchor_id : #{project_anchor.id})"
      return
    end
    log_info "*** setup of token for #{project_anchor.project.name} (project_anchor_id : #{project_anchor.id})"
    config = { url: "https://orbf2.bluesquare.org", token: project_anchor.token }
    dhis2 = project_anchor.project.dhis2_connection
    begin
      current_config = dhis2.get("dataStore/hesabu/hesabu") rescue nil
      resp = if current_config
               dhis2.put("dataStore/hesabu/hesabu", config)
             else
               dhis2.post("dataStore/hesabu/hesabu", config)
             end
    rescue StandardError => error
      puts "ERROR #{error&.response&.body} : #{error}"
    end
    log_info resp
  end

  def deploy_dhis2_app(project_anchor)
    unless project_anchor.token
      log_info "INFO skipping no token for #{project_anchor.project.name} (project_anchor_id : #{project_anchor.id})"
      return
    end

    project = project_anchor.project

    dhis2_url = project.dhis2_url
    dhis2_user = project.user
    dhis2_password = project.password
    puts "deploying to #{dhis2_url}"
    push_app = system("curl -s -H 'Accept: application/json' -X POST -u '#{dhis2_user}:#{dhis2_password}' --compressed -F file=@#{TARGET_FILE_NAME} #{dhis2_url}/api/apps --write-out '%{http_code}' --output /dev/null | grep [^403] | grep [^504] > /dev/null")
    update_app_ref = system("curl -s -X PUT -u '#{dhis2_user}:#{dhis2_password}' -H 'Accept: application/json' #{dhis2_url}/api/apps") if push_app
    puts "deployed"

  end

  def s3
    s3 ||= ::Aws::S3::Resource.new(
      region:      ENV.fetch("S3_SIMULATION_REGION"),
      credentials: ::Aws::Credentials.new(
        ENV.fetch("S3_SIMULATION_ACCESS"),
        ENV.fetch("S3_SIMULATION_SECRET")
      )
    )
  end

  def download_latest_build
    log_info("downloading latest build from s3")
    s3_object = s3.bucket("hesabu-manager-build").object("Hesabu.zip")
    log_info("   last modification : #{s3_object.last_modified}")
    s3_object.get(response_target: TARGET_FILE_NAME)
    log_info("downloaded latest build from s3")
  end
end
