class IncentivesController < PrivateController
  helper_method :incentive
  attr_reader :incentive

  def new
    @incentive = IncentiveConfig.new
    @project = current_user.project
  end

  def create
    @incentive = IncentiveConfig.new(incentive_params)
    @project = current_user.project
    if @incentive.valid?

      @incentive.activity_incentives = @project.packages.find(@incentive.package).fetch_activities.map do |activity|
        ActivityIncentive.new(
          activity: activity,
          value:    0.0
        )
      end
    else
    raise @incentive.errors.full_messages
      render "new"
    end
  end

  def update; end

  def incentive_params
    params.require(:incentive_config)
          .permit(:package,
                  :state,
                  :entity_groups,
                  :start_date,
                  :end_date)
  end
end
