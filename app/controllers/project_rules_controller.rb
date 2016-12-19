class ProjectRulesController < PrivateController
  helper_method :rule
  attr_reader :rule

  def new
    if current_project.missing_rules_kind.empty?
      flash[:alert] = "Sorry you can't create a new rule for the package, edit existing one."
      redirect_to(root_path)
      return
    end

    @rule = current_project.rules.build(kind: current_project.missing_rules_kind.first)
    @rule.formulas.build(rule: @rule)
  end

  def edit
    @rule = current_project.payment_rule
    @rule.valid?

  end

  def create
      if current_project.missing_rules_kind.empty?
      flash[:alert] = "Sorry you can't create a new payment rule, edit existing one."
      redirect_to(root_path)
      return
    end

    @rule = current_project.rules.build(rule_params.merge(kind: current_project.missing_rules_kind.first))
    puts @rule.valid?
    puts @rule.errors.full_messages
    if @rule.save
      flash[:notice] = "Rule created !"
      redirect_to(root_path)
    else
      render action: "new"
    end
  end

  def update
    @rule = current_package.rules.find(params[:id])
    @rule.update_attributes(rule_params)
    puts @rule.valid?
    puts @rule.errors.full_messages
    if @rule.save
      flash[:notice] = "Rule updated !"
      redirect_to(root_path)
    else
      render action: "edit"
    end
  end

  private

  def current_project
    current_user.project
  end

  def rule_params
    params.require(:rule)
          .permit(:name,
                  :kind,
                  formulas_attributes: [
                    :id, :code, :description, :expression, :_destroy
                  ])
  end
end
