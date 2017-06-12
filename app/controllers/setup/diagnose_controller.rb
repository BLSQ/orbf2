class Setup::DiagnoseController < PrivateController
  helper_method :project, :contracted_entities, :minimum_packages, :pyramid
  attr_accessor :contracted_entities, :project, :minimum_packages, :pyramid
  def index

    @minimum_packages = params[:minimum_packages] ? params[:minimum_packages].to_i : 1
    @project = current_project
    @pyramid = Pyramid.from(project)
    @contracted_entities = pyramid.org_units_in_all_groups([project.entity_group.external_reference])

  end
end
