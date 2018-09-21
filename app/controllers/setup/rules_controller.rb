# frozen_string_literal: true

class Setup::RulesController < PrivateController
  helper_method :rule
  attr_reader :rule

  def new
    if current_package.missing_rules_kind.empty?
      flash[:alert] = "Sorry you can't create a new rule for the package, edit existing one."
      redirect_to redirect_to(root_path)
      return
    end

    @rule = current_package.rules.build(kind: kind)
    @rule.formulas.build(rule: @rule)
  end

  def edit
    @rule = current_package.rules.find(params[:id])
    @rule.valid?
  end

  def create
    if current_package.missing_rules_kind.empty?
      flash[:alert] = "Sorry you can't create a new rule for the package, edit existing one."
      redirect_to redirect_to(root_path)
      return
    end

    @rule = current_package.rules.build(
      rule_params.merge(kind:    kind,
                        package: current_package)
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
                  decision_tables_attributes: %i[id content])
  end
end
