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

    new_program = program.deep_clone(
      include:        {
        users:          [:program],
        project_anchor: {
          projects:        project_includes,
          dhis2_snapshots: []
        }
      },
      use_dictionary: true
    ) do |original, kopy|
      if original.class.name == "User"
        new_password = SecureRandom.uuid
        kopy.password = new_password
        kopy.password_confirmation = new_password
      end
    end

    database_yml = ERB.new(IO.read("config/database.yml")).result(binding)

    # load instead of safe_load to prevent : Psych::BadAlias: Unknown alias: default
    dbconfigs = YAML.load(database_yml)
    dbconfig = dbconfigs["test"]
    puts "program loaded"
    ActiveRecord::Base.establish_connection(dbconfig)
    puts "saving data in #{dbconfig.except('password')}"
    new_program.save!
    puts "program is #{new_program.id}"
  end
end
