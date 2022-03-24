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
      begin
        setup_token(project_anchor)
      rescue StandardError => e
        puts "FAILED TO SETUP #{project_anchor.id} #{e.message}"
      end
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
      begin
        deploy_dhis2_app(project_anchor)
      rescue StandardError => e
        puts "FAILED TO DEPLOY #{project_anchor.id} #{e.message}"
      end
    end
  end

  TARGET_FILE_NAME = "/tmp/Hesabu.zip"

  def log_info(message)
    puts message
  end

  def log_error(message)
    puts "\e[31mERROR\e[0m #{message}"
  end

  def setup_token(project_anchor)
    unless project_anchor.token
      log_info "INFO skipping no token for #{project_anchor.project.name} (project_anchor_id : #{project_anchor.id})"
      return
    end
    config = { url: Scorpio.orbf2_url, token: project_anchor.token, program_id: project_anchor.program_id }
    project = project_anchor.project
    dhis2 = Dhis2::Client.new(project.dhis_configuration.merge(timeout: 20))
    log_info "*** setup of token for #{project_anchor.project.name} (project_anchor_id : #{project_anchor.id}, #{project.dhis2_url})"
    begin
      current_config = begin
                         dhis2.get("dataStore/hesabu/hesabu")
                       rescue StandardError
                         nil
                       end
      resp = if current_config
               dhis2.put("dataStore/hesabu/hesabu", config)
             else
               dhis2.post("dataStore/hesabu/hesabu", config)
             end
    rescue StandardError => e
      log_error "#{e&.response&.body} : #{e}"
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
    log_info "*** deploying for #{project_anchor.project.name} (project_anchor_id : #{project_anchor.id}, #{project.dhis2_url})"
    deploy_command = "curl --connect-timeout 20 -s -H 'Accept: application/json' -X POST -u '#{dhis2_user}:#{dhis2_password}' --compressed -F file=@#{TARGET_FILE_NAME} #{dhis2_url}/api/apps --write-out '%{http_code}' --output /dev/null | grep [^403] | grep [^504] | grep [^000] > /dev/null"
    push_app = system(deploy_command)
    update_app_ref = system("curl -s -X PUT -u '#{dhis2_user}:#{dhis2_password}' -H 'Accept: application/json' #{dhis2_url}/api/apps") if push_app
    if push_app
      log_info "deployed"
    else
      log_error "not deployed"
    end
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
