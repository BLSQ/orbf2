module Invoicing
  class InvoicingOptions
    def initialize(publish_to_dhis2: false, force_project_id:, allow_fresh_dhis2_data: false)
      @publish_to_dhis2 = publish_to_dhis2
      @force_project_id = force_project_id
      @allow_fresh_dhis2_data = allow_fresh_dhis2_data
    end

    def publish_to_dhis2?
      @publish_to_dhis2
    end

    def allow_fresh_dhis2_data?
      @allow_fresh_dhis2_data
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