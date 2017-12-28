namespace :groups do
  def confirm?(message)
    puts "#{message} Y to go further"
    STDIN.gets.chomp == "Y"
  end

  def perform(update, orgunit_id)
    # WHdJlwRgg8z    RBF Facilities
    # g5G55uqglob     Primary
    # Xm2s7GkiN2O    Private
    # yNNcJybATnM    CPA / PCA ( / CPA / PCA)
    project_anchor_id = 6

    orgunit_group_to_remove = "g3sUUjQLxlK"
    orgunit_group_to_remove_primary = "g5G55uqglob"
    orgunit_group_to_add = "yNNcJybATnM"

    orgunit_snapshots = ProjectAnchor.find(project_anchor_id)
                                     .dhis2_snapshots
                                     .where(kind: "organisation_units")
                                     .order(id: :asc)

    orgunit_groups_snapshots = ProjectAnchor.find(project_anchor_id)
                                            .dhis2_snapshots
                                            .where(kind: "organisation_unit_groups")
                                            .order(id: :asc)
    raise "cancel" if update && !confirm?("Are you sure")
    orgunit_groups_snapshots.each do |snapshot|
      puts "************* #{snapshot.year} #{snapshot.month} - #{snapshot.kind}"
      snapshot.content.each do |row|
        orgunit_group_id = row["table"]["id"]
        orgunit_group_name = row["table"]["name"]
        # puts " #{orgunit_group_id} #{orgunit_group_name}"
        next unless [orgunit_group_to_remove, orgunit_group_to_add].include?(orgunit_group_id)
        puts "--- " + orgunit_group_name + " (" + orgunit_group_id + " / " + (row["table"]["code"] || "") + ")"

        orgunits = row["table"]["organisation_units"]
        add_remove_from_groups(orgunits, orgunit_group_to_remove, orgunit_group_to_add, orgunit_group_name, orgunit_group_id, orgunit_id)

        add_remove_from_groups(orgunits, orgunit_group_to_remove_primary, nil, orgunit_group_name, orgunit_group_id, orgunit_id)
      end
      snapshot.save! if update
    end

    puts  "*************************************************************************"
    puts  "*************************************************************************"

    orgunit_snapshots.each do |snapshot|
      puts "************* #{snapshot.year} #{snapshot.month} - #{snapshot.kind}"

      snapshot.content.each do |row|
        next unless row["table"]["id"] == orgunit_id
        orgunit_name = row["table"]["name"]
        puts "--- " + orgunit_name

        orgunit_groups = row["table"]["organisation_unit_groups"]
        add_remove(orgunit_groups, orgunit_group_to_remove, orgunit_group_to_add, orgunit_name)
        add_remove(orgunit_groups, orgunit_group_to_remove_primary, nil, orgunit_name)
      end
      snapshot.save! if update
    end
  end

  def add_remove(collection, item_to_remove, item_to_add, orgunit_name)
    before = collection.to_json
    puts "  groups" + before

    if item_to_remove && collection.include?("id" => item_to_remove)
      puts "removing #{item_to_remove} from #{orgunit_name}"
      collection.delete("id" => item_to_remove)
    end

    if item_to_add && !collection.include?("id" => item_to_add)
      puts "adding #{item_to_add} from #{orgunit_name}"
      collection.push("id" => item_to_add)
    end

    after = collection.to_json
    puts " removed : #{JSON.parse(before) - JSON.parse(after)}"
    puts " added   : #{JSON.parse(after) - JSON.parse(before)}"
  end

  def add_remove_from_groups(orgunits, orgunit_group_to_remove, orgunit_group_to_add, orgunit_group_name, orgunit_group_id, orgunit_id)
    before = orgunits.to_json
    puts " to remove : #{orgunit_group_to_remove}"

    if orgunit_group_to_remove && orgunit_group_id == orgunit_group_to_remove && orgunits.include?("id" => orgunit_id)
      puts "removing #{orgunit_id} from #{orgunit_group_name}"
      orgunits.delete("id" => orgunit_id)
    end

    if orgunit_group_to_add && orgunit_group_id == orgunit_group_to_add && !orgunits.include?("id" => orgunit_id)
      puts "adding #{orgunit_id} from #{orgunit_group_name}"
      orgunits.push("id" => orgunit_id)
    end

    after = orgunits.to_json
    puts " removed : #{JSON.parse(before) - JSON.parse(after)}"
    puts " added   : #{JSON.parse(after) - JSON.parse(before)}"
  end

  desc "change"
  task change: :environment do
    orgunit_id = "enzW7LnbkzO"
    update = ENV["PERFORM"] == "true"
    update = false
    %w[Pf8AScjVxL4 R6MgsXbAnKo fDwjp4uWrHR i1FYNZRrGYA tE2YEFSF82H w4WmqWqTolR RsniEGdiFvR D7MxMCNIQm5 YPjqA9F4IQV sfr0eSr3rdm
       bbGRNib2MOH J2HlkrSqJC2 hBu1Xfv9XxV ei5Qt6lTVZx zI4Mn9rqFhu U5fBURbnnOV QjeP9QZw3Hu TrzehJ0VuZP mxoNWN70XzP uKi9NBUam2j].each do |orgunit_id|
      perform(update, orgunit_id)
    end
  end
end
