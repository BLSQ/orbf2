# frozen_string_literal: true

Rake::Task["spec"].clear if Rake::Task.task_defined?("spec")

namespace :spec do
  desc "Run models"
  task :models do
    cmds = [
      %w[rspec spec --tag @type:models]
    ]
    run_commands(cmds)
  end

  desc "Run feature/request/system specs"
  task :system do
    cmds = [
      %w[rspec spec --tag @type:system]
    ]
    run_commands(cmds)
  end
end

desc "Run specs (without system)"
task :spec do
  cmds = [
    %w[rspec spec --color --tag ~@type:system]
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({ "RAILS_ENV" => "test", "force" => "yes" }, *cmd) || raise("#{cmd} failed!")
  end
end
