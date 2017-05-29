namespace :contract do
  desc "List contract and main entity"
  task list: :environment do
    primary_groups = "VVxYQ41nD2P"
    group_set = "pHH6kYd3i98"
    project_id = 9

    project = Project.find(project_id)
    pyramid = Pyramid.from(project)
  end

  desc "equity bonus"
  task equity: :environment do
    project_id = 9

    project = Project.find(project_id)
    pyramid = Pyramid.from(project)

    equity_bonus_decisions = Decision::Table.new(File.read("../equity-bonus-original.csv"))

    orgs_level3 = pyramid.org_units.map do |orgunit|
      next unless orgunit.level == 3
      parent = pyramid.org_unit(orgunit.parent["id"])
      values = equity_bonus_decisions.find(level_3: fix_name(orgunit.name))
      puts "no values for '#{fix_name(parent.name)}' '#{fix_name(orgunit.name)}'" unless values
      [parent.id, fix_name(parent.name), orgunit.id, fix_name(orgunit.name), values ? values["equity_bonus"]: 0]
    end.compact

    orgs_level3 = orgs_level3.sort_by { |arr|
      [arr[1], arr[3]]
    }

    csv_string = CSV.generate do |csv|
      orgs_level3.each do |row|
        csv << row
      end
    end
    puts csv_string
  end

  def fix_name(name)
    name.strip.gsub("\n","").gsub("\r","")
  end
end
