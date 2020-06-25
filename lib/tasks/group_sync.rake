namespace :contracts do
    desc "group_sync"
    task group_sync: :environment do
      ProjectAnchor.find_each do |anchor|
        SynchroniseGroupsWorker.perform_async(anchor.id)
      end
    end
  end
