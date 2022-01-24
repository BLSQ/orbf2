module Jobs
  class LastJobExecution
    attr_accessor :orgunit_id, :period, :orgunit_details, :status, :executed_at

    def initialize(orgunit_id:, period:, orgunit_details:, status:, executed_at:)
      @orgunit_id = orgunit_id
      @period = period
      @orgunit_details = orgunit_details
      @status = status
      @executed_at = executed_at
    end
  end

  class LastJobsService
    def initialize(project, pyramid)
      @project = project
      @pyramid = pyramid
    end

    def jobs
      project.project_anchor.dhis2_logs.last(10).reverse.map do |dhis2_log|
        orgunit_id = dhis2_log.orgunit_ids.first

        LastJobExecution.new(
          orgunit_id:      orgunit_id,
          period:          dhis2_log.periods.last,
          orgunit_details: parent_names(orgunit_id),
          status:          dhis2_log.status,
          executed_at:     dhis2_log.created_at
        )
      end
    end

    private

    attr_reader :project, :pyramid

    def parent_names(orgunit_id)
      return nil unless pyramid

      pyramid.org_unit_parents(orgunit_id).map(&:name).join(" > ")
    end
  end
end
