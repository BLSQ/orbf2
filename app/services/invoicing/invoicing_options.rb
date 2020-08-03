# frozen_string_literal: true

module Invoicing
  class InvoicingOptions
    def initialize(publish_to_dhis2: false, force_project_id:, allow_fresh_dhis2_data: false, invoicing_job: nil, sidekiq_job_ref: nil)
      @publish_to_dhis2 = publish_to_dhis2
      @force_project_id = force_project_id
      @allow_fresh_dhis2_data = allow_fresh_dhis2_data
      @invoicing_job = invoicing_job
      @sidekiq_job_ref = sidekiq_job_ref
    end

    def publish_to_dhis2?
      @publish_to_dhis2
    end

    def allow_fresh_dhis2_data?
      @allow_fresh_dhis2_data
    end

    def ignore_non_contracted?
      @publish_to_dhis2
    end

    def invoicing_job_id
      @invoicing_job&.id
    end

    attr_reader :force_project_id, :sidekiq_job_ref

    def self.default_options
      Invoicing::InvoicingOptions.new(
        publish_to_dhis2: true,
        force_project_id: nil
      )
    end
  end
end
