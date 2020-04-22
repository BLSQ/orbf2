# frozen_string_literal: true

namespace :duplicate_jobs do
  desc "clear duplicated enqueued jobs"
  task clear: :environment do
    jobs = {}
    Sidekiq::Queue.all.each do |queue|
      queue.each do |job|
        key = "#{job.klass} #{job.args}"
        jobs[key] ||= []
        jobs[key] << job
      end
    end

    duplicated_jobs = jobs.select { |_k, v| v.size > 1 }.to_a
    deleted = 0
    duplicated_jobs.each do |_k, v|
      # keep the first, delete the other one
      v[1..-1].each do |job|
        job.delete
        deleted += 1
      end
    end
    puts "duplicate_jobs:clear => deleted #{deleted} duplicated jobs" if deleted > 0
  end
end
