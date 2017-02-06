class SynchroniseDegDsWorker
  include Sidekiq::Worker

  def perform(project_anchor_id, now = Time.now.utc)
    project_anchor = ProjectAnchor.find(project_anchor_id)
    project = project_anchor.projects.for_date(now)

    project.packages.each do |package|
      synchronize(package)
    end
  end

  def synchronize(package)
    puts "Synchronizing #{package.name} - activities #{package.activities.size}"
    package.activities.each do |activity|
      puts "\t#{activity.name}"
      package.states.each do |state|
        activity_state = activity.activity_state(state)
        if activity_state
          puts "\t#{state.name}\t#{activity_state.name}\t#{activity_state.external_reference}"
        else
          puts "WARN no activity state for #{state.name} in #{activity} for package #{package.name}"
        end
      end
    end
  end
end
