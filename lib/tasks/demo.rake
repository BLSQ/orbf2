
namespace :demo do
  desc "Run invoice from commandline"
  task invoice: :environment do
    year = "2017"
    quarter = "4"
    orgunit_ext_id = "eov2pDYbAK0"
    invoicing_period = "2017Q4"
    project_id = "9"

    project = Project.fully_loaded.find(project_id)
    orbf_project = MapProjectToOrbfProject.new(project).map
    exported_values = value_to_s(Orbf::RulesEngine::FetchAndSolve.new(orbf_project, orgunit_ext_id, invoicing_period).call.map { |v| v.except(:comment) })

    options = {
      publisher_ids:          [],
      mock_values:            false,
      force_project_id:       project_id,
      allow_fresh_dhis2_data: true
    }

    invoices = InvoicesForEntitiesWorker.new.perform(
      project.project_anchor_id,
      year,
      quarter,
      [orgunit_ext_id],
      options
    )[orgunit_ext_id]

    legacy_exported_values = value_to_s(Publishing::Dhis2InvoicePublisher.new.to_values(invoices).map { |v| v.except(:comment) })

    puts (exported_values - legacy_exported_values).size
    puts (legacy_exported_values - exported_values).size
  end

  def value_to_s(values)
    values.each do |v|
      v[:value] = format("%.10f", v[:value])
    end
  end
end
