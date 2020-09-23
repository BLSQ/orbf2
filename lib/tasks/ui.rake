# frozen_string_literal: true

namespace :ui do
  def log_info(message)
    puts message
  end

  def setup_token(project_anchor)
    unless project_anchor.token
      puts "INFO skipping no token for #{project_anchor.project.name} (project_anchor_id : #{project_anchor.id})"
      return
    end
    puts "*** setup of token for #{project_anchor.project.name} (project_anchor_id : #{project_anchor.id})"
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
    puts resp
  end

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
end
