
namespace :demo do
    desc "Run invoice from commandline"
    task invoice: :environment do

        orgunit_ext_id = 'eov2pDYbAK0'
        invoicing_period = '2017Q4'
        project_id= '9'

        project = Project.fully_loaded.find(project_id)
        orbf_project = MapProjectToOrbfProject.new(project).map
        Orbf::RulesEngine::FetchAndSolve.new(orbf_project, orgunit_ext_id, invoicing_period).call
    end
end