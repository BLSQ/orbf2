# frozen_string_literal: true

module Fetchers
  class Progress
    attr_accessor :kind, :page, :page_size, :page_count, :filter, :start, :fields

    def initialize(options)
      @start = Time.current
      @kind = options.fetch(:kind)
      @page = 1
      @page_size = options.fetch(:page_size)
      @filter = options.fetch(:filter)
      @fields = options.fetch(:fields)
    end

    def log_progress(paged_data)
      puts "#{Time.current} \t Processed #{kind} page #{page} of #{page_count || '?'} "\
            " (Size: #{paged_data.size}, total time : #{Time.current - start}) #{filter} #{fields}"
    end
  end

  class GenericSnapshotFetcher
    attr_reader :fields, :start

    def initialize(fields: ":all")
      @fields = fields
    end

    def fetch_data(project, kind, filter: nil, page_size: 5000)
      data = []
      begin
        dhis2 = project.dhis2_connection
        progress = Progress.new(kind: kind, page_size: page_size, filter: filter, fields: fields)
        paged_data = fetch_paged_data(dhis2, data, progress)
        progress.page_count = paged_data.pager.page_count
        if progress.page_count > 1
          (2..progress.page_count).each do |page|
            progress.page = page
            fetch_paged_data(dhis2, data, progress)
          end
        end
      rescue RestClient::Exception => e
        Rails.logger.info "#{kind} #{e.message}"
        raise "#{kind} #{e.message}"
      end
      data
    end

    def fetch_paged_data(dhis2, data, progress)
      actual_page = progress.page == 1 ? nil : progress.page
      paged_data = dhis2.send(progress.kind).list(
        page:      actual_page,
        fields:    fields,
        page_size: progress.page_size,
        filter:    progress.filter
      )
      progress.log_progress(paged_data)
      data.push(*paged_data)
      paged_data
    end
  end
end
