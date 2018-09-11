# frozen_string_literal: true

module Fetchers
  class GenericSnapshotFetcher
    attr_reader :fields

    def initialize(fields: ":all")
      @fields = fields
    end

    def fetch_data(project, kind, filter: nil, page_size: 5000)
      data = []
      begin
        start = Time.new
        dhis2 = project.dhis2_connection
        paged_data = dhis2.send(kind).list(fields: fields, page_size: page_size, filter: filter)
        data.push(*paged_data)
        page_count = paged_data.pager.page_count

        log_progress(1, page_count, paged_data, start, filter)
        if page_count > 1
          (2..page_count).each do |page|
            paged_data = dhis2.send(kind).list(fields: fields, page_size: page_size, page: page, filter: filter)
            log_progress(page, page_count, paged_data, start, filter)
            data.push(*paged_data)
          end
        end
      rescue RestClient::Exception => e
        Rails.logger.info "#{kind} #{e.message}"
        raise "#{kind} #{e.message}"
      end
      data
    end

    def log_progress(page, page_count, paged_data, start, filter)
      puts "#{Time.new} \t Processed page #{page} of #{page_count} "\
            " (Size: #{paged_data.size}, total time : #{Time.new - start}) #{filter} #{fields}"
    end
  end
end
