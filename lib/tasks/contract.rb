namespace :contract do
  desc "List contract and main entity"
  task list: :environment do
    primary_groups = "VVxYQ41nD2P"
    group_set = "pHH6kYd3i98"
    project_id = 9

    project = Project.find(project_id)
    pyramid = Pyramid.from(project)

  end
end
