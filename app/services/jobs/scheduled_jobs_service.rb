module Jobs
  class ScheduledJob
    attr_accessor :orgunit_id, :period, :orgunit_details

    def initialize(orgunit_id:, period:, orgunit_details:)
      @orgunit_id = orgunit_id
      @period = period
      @orgunit_details = orgunit_details
    end
  end

  class ScheduledJobsService
    def initialize(project, pyramid)
      @project = project
      @pyramid = pyramid
    end

    def jobs
      Sidekiq::Queue.all.each_with_object([]) do |queue, array|
        queue.each do |job|
          next unless job.klass == "InvoiceForProjectAnchorWorker"
          next unless job.args[0].to_s == project.project_anchor_id.to_s

          array.push(to_scheduled_job(job))
        end
      end
    end

    private

    attr_reader :project, :pyramid

    def to_scheduled_job(job)
      orgunit_id = job.args[3].first

      ScheduledJob.new(
        period:          "#{job.args[1]}Q#{job.args[2]}",
        orgunit_id:      orgunit_id,
        orgunit_details: parent_names(orgunit_id)
      )
    end

    def parent_names(orgunit_id)
      return nil unless pyramid

      pyramid.org_unit_parents(orgunit_id).map(&:name).join(" > ")
    end
  end
end
