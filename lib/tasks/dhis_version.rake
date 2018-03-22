namespace :dhis2_version do
  def update_project(project)
    version = project.dhis2_connection.system_infos.get["version"]
    project.update!(dhis2_version: version)
    puts "#{project.name} DHIS2 version update to #{version}"
  rescue StandardError => e
    puts "#{project.name} (#{project.id}) failed to update version with #{e.message}"
  end

  desc "Queries all projects DHIS2 and get the current version to update the projects dhis_version field"
  task update: :environment do
    Project.all.each do |project|
      update_project(project)
    end
  end
end
