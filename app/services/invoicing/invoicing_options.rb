# frozen_string_literal: true

module Invoicing
  class InvoicingOptions
    def initialize(
      publish_to_dhis2: false,
      force_project_id:,
      allow_fresh_dhis2_data: false,
      do_nothing_if_not_contracted: true
    )
      @publish_to_dhis2 = publish_to_dhis2
      @force_project_id = force_project_id
      @allow_fresh_dhis2_data = allow_fresh_dhis2_data
      @do_nothing_if_not_contracted = do_nothing_if_not_contracted
    end

    def publish_to_dhis2?
      @publish_to_dhis2
    end

    def allow_fresh_dhis2_data?
      @allow_fresh_dhis2_data
    end

    def do_nothing_if_not_contracted?
      @do_nothing_if_not_contracted
    end

    attr_reader :force_project_id

    def self.default_options
      Invoicing::InvoicingOptions.new(
        publish_to_dhis2: true,
        force_project_id: nil
      )
    end
  end
end
