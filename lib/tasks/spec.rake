# frozen_string_literal: true

if Rake::Task.task_defined?("spec")
  Rake::Task["spec"].clear
  # Clear out rspec/rails tasks as well, to avoid double run
  Rake::Task["spec:models"].clear
end

namespace :spec do
  desc "Run models"
  task :models do
    cmds = [
      %w[rspec spec --tag @type:models]
    ]
    run_commands(cmds)
  end

  desc "Run full data test"
  task :data_test do
    cmds = [
      %w[rspec spec --tag @data_test]
    ]
    run_commands(cmds)
  end
end

desc "Run specs (without system)"
task :spec do
  cmds = [
    %w[rspec spec --color --tag ~@type:system --tag ~@data_test]
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({ "RAILS_ENV" => "test", "force" => "yes" }, *cmd) || raise("#{cmd} failed!")
  end
end
