# frozen_string_literal: true

require "dhis_demo_resolver"

class Setup::SeedsController < PrivateController
  def index
    current_user.program.create_project_anchor unless current_user.program.project_anchor
    project_anchor = current_user.program.project_anchor
    project_factory = ProjectFactory.new
    suffix = project_factory.normalized_suffix
    project = project_factory.build(
      dhis2_url:      dhis2_url,
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: project_anchor
    )
    project_factory.update_links(project, suffix)
    project_factory.additional_seed_actions(project, suffix)
    project_anchor.projects.destroy_all
    project_anchor.projects.push project

    project.save!
    current_user.save!
    SynchroniseDegDsWorker.new.perform(project_anchor.id)
    Dhis2SnapshotWorker.new.perform(project_anchor.id)
    flash[:notice] = " created package and rules for #{suffix} : #{project.packages.map(&:name).join(', ')}"
    redirect_to root_path
  end

  def dhis2_url
    if params[:local]
      "http://127.0.0.1:8085/"
    else
      resolve_play_demo_url
    end
  end

  def resolve_play_demo_url
    DhisDemoResolver.new.call
  end
end
