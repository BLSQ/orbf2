# frozen_string_literal: true

module Fetchers
  class GenericSnapshotFetcher
    attr_reader :fields, :start

    def initialize(fields: ":all")
      @fields = fields
    end

    def fetch_data(project, kind, filter: nil, page_size: 5000)
      data = []
      begin
        @start = Time.new
        dhis2 = project.dhis2_connection
        page_count= nil
        paged_data = fetch_paged_data(dhis2, data, kind, 1, page_size, page_count, filter)
        page_count = paged_data.pager.page_count
        if page_count > 1
          (2..page_count).each do |page|
            fetch_paged_data(data, kind, page, page_size, page_count, filter)
          end
        end
      rescue RestClient::Exception => e
        Rails.logger.info "#{kind} #{e.message}"
        raise "#{kind} #{e.message}"
      end
      data
    end

    def fetch_paged_data(dhis2, data, kind, page, page_size, page_count, filter)
      page = nil if page == 1
      paged_data = dhis2.send(kind).list(
        page:      page,
        fields:    fields,
        page_size: page_size,
        filter:    filter
      )
      log_progress(page, page_count, paged_data, filter)
      data.push(*paged_data)
      paged_data
    end

    def log_progress(page, page_count, paged_data, filter)
      puts "#{Time.new} \t Processed page #{page} of #{page_count} "\
            " (Size: #{paged_data.size}, total time : #{Time.new - start}) #{filter} #{fields}"
    end
  end
end
