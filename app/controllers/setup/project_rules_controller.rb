class Setup::ProjectRulesController < PrivateController
  helper_method :project_rule
  attr_reader :project_rule

  def index
    data_compound = current_project.project_anchor.nearest_data_compound_for(Date.new) || DataCompound.from(current_project)
    @orbf_project = MapProjectToOrbfProject.new(
      current_project,
      data_compound.indicators
    ).map

    @packages = if params[:package]
                  [@orbf_project.packages[params[:package].to_i - 1]]
                else
                  @orbf_project.packages
                end
  end

  def new
    @project_rule = current_project.payment_rules.build(rule_attributes: { kind: "payment" })
    project_rule.rule.formulas.build
  end

  def edit
    @project_rule = current_project.payment_rules.find(params[:id])
    project_rule.valid?
    project_rule.rule.valid?
  end

  def create
    payment_rules_attributes = rule_params
    payment_rules_attributes[:rule_attributes][:kind] = "payment"
    @project_rule = current_project.payment_rules.build(payment_rules_attributes)
    Rails.logger.info project_rule.valid?
    Rails.logger.info project_rule.errors.full_messages
    if project_rule.save
      flash[:notice] = "Rule created !"
      redirect_to(root_path)
    else
      project_rule.rule.formulas.build if project_rule.rule.formulas.empty?
      render action: "new"
    end
  end

  def update
    @project_rule = current_project.payment_rules.find(params[:id])
    project_rule.update(rule_params)
    Rails.logger.info project_rule.valid?
    Rails.logger.info project_rule.errors.full_messages
    if project_rule.save
      flash[:notice] = "Rule updated !"
      redirect_to(root_path)
    else
      project_rule.rule.formulas.build if project_rule.rule.formulas.empty?
      render action: "edit"
    end
  end

  private

  def rule_params
    params.require(:payment_rule)
          .permit(
            :frequency,
            package_ids:     [],
            rule_attributes: [
              :id,
              :name,
              formulas_attributes: %i[id code short_name description expression frequency _destroy]
            ]
          )
  end
end
