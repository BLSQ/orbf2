class RulesController < PrivateController
  helper_method :rule
  attr_reader :rule

  def new
    package = current_user.project.packages.find(params[:package_id])
    if !package.activity_rule.present? && !package.activity_rule.present?
      @rule = package.rules.build(kind: "activity")
    elsif !package.package_rule.present?
      @rule = package.rules.build(kind: "package")
      end
end

  def edit; end

  def create; end

  def updated; end

  private

  def rule_params
    params.require(:rule)
          .permit(:name,
                  :kind,
                  formulas_attributes: [:id, :code, :description, :expression, :_destroy])
  end
end
