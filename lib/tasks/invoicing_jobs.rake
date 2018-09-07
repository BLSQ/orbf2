# frozen_string_literal: true

namespace :invoicing_jobs do
  desc "Schedule discarding process"
  task discard: :environment do
    jid = DiscardInvoicingJobWorker.perform_async
    puts "DiscardInvoicingJobWorker scheduled : #{jid}"
  end
end
