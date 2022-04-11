# frozen_string_literal: true

class Setup::RulesController < PrivateController
  helper_method :rule
  attr_reader :rule

  def new
    reasons = reasons_rule_can_not_be_added(kind)
    if reasons.any?
      flash[:alert] = "Sorry, #{reasons.first}"
      redirect_to(root_path)
      return
    end

    @rule = current_package.rules.build(kind: kind, name: "#{current_package.name} - #{kind}")
    @rule.formulas.build(rule: @rule)
  end

  def edit
    @rule = current_package.rules.find(params[:id])
    @decision_tables = @rule.decision_tables
    @rule.valid?
  end

  def create
    reasons = reasons_rule_can_not_be_added(kind)
    if reasons.any?
      flash[:alert] = "Sorry, #{reasons.first}"
      redirect_to(root_path)
      return
    end

    @rule = current_package.rules.build(
      rule_params.merge(package: current_package)
    )
    Rails.logger.info @rule.valid?
    Rails.logger.info @rule.errors.full_messages
    if @rule.save
      flash[:notice] = "Rule created !"
      redirect_to(root_path)
    else
      render action: "new"
    end
  end

  def update
    @rule = current_package.rules.find(params[:id])
    @rule.update(rule_params)
    Rails.logger.info @rule.valid?
    Rails.logger.info @rule.errors.full_messages
    flash[:notice] = "Rule updated !" if @rule.save

    render action: "edit"
  end

  private

  def reasons_rule_can_not_be_added(rule_kind)
    reasons = []
    # rubocop:disable Metrics/LineLength
    reasons << "you can't create a new rule for the package" if current_package.missing_rules_kind.empty?
    reasons << "this kind is not allowed for this package" unless current_package.rule_allowed?(rule_kind: rule_kind)
    reasons << "there is already a rule for #{rule_kind}" if current_package.already_has_rule?(rule_kind: rule_kind)
    # rubocop:enable Metrics/LineLength
    reasons
  end

  def kind
    if params[:kind]
      (current_package.missing_rules_kind & [params[:kind]]).first
    else
      current_package.missing_rules_kind.first
    end
  end

  def current_package
    @package ||= current_project.packages.find(params[:package_id])
  end

  def rule_params
    params.require(:rule)
          .permit(:name,
                  :kind,
                  formulas_attributes:        Formula::WHITELISTED_FIELDS,
                  decision_tables_attributes: %i[id content name comment source_url start_period end_period _destroy])
  end
end
