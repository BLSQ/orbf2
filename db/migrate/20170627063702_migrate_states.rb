class MigrateStates < ActiveRecord::Migration[5.0]
  class Project < ApplicationRecord
    has_many :packages, dependent: :destroy
    has_many :activities, dependent: :destroy, inverse_of: :project
  end

  class Activity < ApplicationRecord
    belongs_to :project, inverse_of: :activities
    has_many :activity_states, dependent: :destroy
  end

  class ActivityState < ApplicationRecord
    belongs_to :activity, inverse_of: :activity_states
    belongs_to :state
  end

  class State < ApplicationRecord
    def code
      name.parameterize(separator: "_")
    end
  end

  class Package < ApplicationRecord
    belongs_to :project, inverse_of: :packages
    has_many :package_states, dependent: :destroy
  end

  class PackageState < ApplicationRecord
    belongs_to :package
    belongs_to :state
  end

  def up
    states_original = State.all.where("project_id is null").to_a
    return if states_original.empty?

    puts "Current : states_original #{states_original.size} : #{states_original.map(&:code).join(',')} "
    Project.find_each do |project|
      new_project_states = states_original.map do |state|
        [state, State.find_or_create_by(name: state.name, project_id: project.id)]
      end.to_h

      used_states = []
      package_states = project.packages.flat_map(&:package_states)
      activity_states = project.activities.flat_map(&:activity_states)
      state_related_records = package_states + activity_states
      state_related_records.each do |state_related_record|
        new_state = new_project_states[state_related_record.state]
        used_states.push(new_state)
        state_related_record.update_attributes(state: new_state)
      end
      puts "Project #{project.id} - #{project.name} : used_states #{used_states.uniq.map(&:code).join(',')}"
      unused_states = new_project_states.values - used_states
      unused_states.each(&:destroy!)
    end
    State.all.where("project_id is null").destroy_all
    states = State.all
    puts "Current : states #{states.size} : #{states.map { |s| [s.code, s.project_id].join(' - ') }.join(',')} "
  end
end
