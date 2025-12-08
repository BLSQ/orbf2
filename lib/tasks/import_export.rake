# frozen_string_literal: true

# assuming you have we will copy the data of that project in the test db
#
# RAILS_ENV=test ./bin/rake db:setup
# PROJECT_ID=109 bundle exec rake import_export:dump_project
# pg_dump --column-inserts --data-only -v --no-acl --no-owner --dbname=scorpio_test -f sample.sql
#
namespace :import_export do
  desc "dump"
  task dump_project: :environment do
    project = Project.find(ENV.fetch("PROJECT_ID"))
    program = project.project_anchor.program

    project_includes = Project.deep_clone_includes
    project_includes[:original] = []

    disable_snapshots_copy = ENV.fetch("DISABLE_SNAPSHOT", "false")=="true"
    puts("disable_snapshots_copy", disable_snapshots_copy)

    config = {
      users:          [:program],
      project_anchor: {
        projects: project_includes
      }
    }

    source_db_config = ActiveRecord::Base.connection_config
    puts("preparing deep_clone")
    new_program = program.deep_clone(
      include: config,
      use_dictionary: true
    ) do |original, kopy|
      # puts(original.class.name+" "+original.id.to_s)
      if original.class.name == "User"
        new_password = SecureRandom.uuid
        kopy.password = new_password
        kopy.password_confirmation = new_password
      end
    end

    database_yml = ERB.new(IO.read("config/database.yml")).result(binding)

    # load instead of safe_load to prevent : Psych::BadAlias: Unknown alias: default
    local_db_configs = YAML.load(database_yml)
    local_db_config = local_db_configs["test"]
    puts "program loaded"
    ActiveRecord::Base.establish_connection(local_db_config)
    puts "saving data in #{local_db_config.except('password')}"
    new_program.save!
    puts "program is #{new_program.id}"

    new_anchor_id = new_program.project_anchor.id
    if disable_snapshots_copy
      puts "skipping snapshots copy, are you sure it's a good idea ? (it's ok only if non production usage)"
    else
      ActiveRecord::Base.establish_connection(source_db_config)

      dhis2_snapshot_ids = program.project_anchor.dhis2_snapshots.pluck(:id)

      dhis2_snapshot_ids.each do |dhis2_snapshot_id|
        ActiveRecord::Base.establish_connection(source_db_config)
        original = Dhis2Snapshot.all.find(dhis2_snapshot_id)
        puts("copying snapshot #{dhis2_snapshot_id} #{original.kind} #{original.year} #{original.month}")
        ActiveRecord::Base.establish_connection(local_db_config)
        Dhis2Snapshot.create!(
          project_anchor_id: new_anchor_id,
          content:           original.content,
          dhis2_version:     original.dhis2_version,
          kind:              original.kind,
          month:             original.month,
          year:              original.year,
          job_id:            original.job_id,
          created_at:        original.created_at,
          updated_at:        original.updated_at
        )        
        ActiveRecord::Base.establish_connection(source_db_config)
      end
    end
  end
end
