class IncentivesController < PrivateController
  helper_method :incentive
  attr_reader :incentive

  def new
    @incentive = IncentiveConfig.new
    @incentive.state = State.configurables.first.id
    @incentive.package = current_user.project.packages.first.id
    @incentive.start_date = Date.today.to_date.beginning_of_month
    @incentive.end_date = Date.today.to_date.end_of_month
    @project = current_user.project
  end

  def create
    @incentive = IncentiveConfig.new(incentive_params)
    @project = current_user.project
    @incentive.package = @project.packages.find(@incentive.package) if @incentive.package.present?

    if @incentive.valid?
      puts @incentive.errors.full_messages
      @incentive.activity_incentives = @incentive.package.fetch_activities.map do |activity|
        ActivityIncentive.new(
          activity: activity,
          value:    0.0
        )
      end
      render "new"
    else
      puts @incentive.errors.full_messages
      # raise @incentive.errors.full_messages
      render "new"
    end
  end

  def update; end

  def incentive_params
    params.require(:incentive_config)
          .permit(:package,
                  :state,
                  :start_date,
                  :end_date,
                  entity_groups: [])
  end
end
