
class ProjectCocAocReferenceWorker
  include Sidekiq::Worker

  def perform(project_id)
    @project = Project.find(project_id)
    @dhis2 = project.dhis2_connection

    category_option_combo = default_category_option_combo
    assign_references(category_option_combo)
  end

  private

  attr_reader :project, :dhis2

  def default_category_option_combo
    category_option_combos = dhis2.category_option_combos.list(
      filter: "name:eq:default",
      fields: "id,name,categoryCombo"
    )

    return if category_option_combos.empty?
    puts "WARN just guessing category option combos... " if category_option_combos.size > 1
    category_option_combos.sort_by! { |coc| coc.category_combo["id"] == default_category_combo.id }
    category_option_combos.first
  end

  def default_category_combo
    @default_category_combo ||= begin
      category_combos = dhis2.category_combos.list(
        filter: "name:eq:default",
        fields: "id,name,isDefault"
      )
      category_combos.sort_by! { |cc| cc.is_default == true }
      category_combos.first
    end
  end

  def assign_references(category_option_combo)
    project.default_coc_reference ||= category_option_combo.id
    project.default_aoc_reference ||= category_option_combo.id
    project.save!
  end
end
