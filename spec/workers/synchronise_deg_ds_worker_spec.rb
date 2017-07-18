require "rails_helper"

RSpec.describe SynchroniseDegDsWorker do
  include_context "basic_context"
  let(:project) { full_project }

  let(:claimed_deg) { "{\"dataElementGroups\":[{\"name\":\"Claimeds - Quantity PMA\",\"shortName\":\"claimed-Quantity PMA\",\"code\":\"claimed-Quantity PMA\",\"dataElements\":[{\"id\":\"cl-ext-1\"},{\"id\":\"cl-ext-2\"}]}]}" }
  let(:verified_deg) { "{\"dataElementGroups\":[{\"name\":\"Verifieds - Quantity PMA\",\"shortName\":\"verified-Quantity PMA\",\"code\":\"verified-Quantity PMA\",\"dataElements\":[]}]}" }
  let(:tarif_deg) { "{\"dataElementGroups\":[{\"name\":\"Tarifs - Quantity PMA\",\"shortName\":\"tarif-Quantity PMA\",\"code\":\"tarif-Quantity PMA\",\"dataElements\":[{\"id\":\"tarif-ext-1\"},{\"id\":\"tarif-ext-2\"}]}]}" }

  let(:claimed_dataset) { "{\"dataSets\":[{\"name\":\"Claimeds - Quantity PMA\",\"shortName\":\"claimed-Quantity PMA\",\"code\":\"claimed-Quantity PMA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }
  let(:verified_dataset) { "{\"dataSets\":[{\"name\":\"Verifieds - Quantity PMA\",\"shortName\":\"verified-Quantity PMA\",\"code\":\"verified-Quantity PMA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }
  let(:tarif_dataset) { "{\"dataSets\":[{\"name\":\"Tarifs - Quantity PMA\",\"shortName\":\"tarif-Quantity PMA\",\"code\":\"tarif-Quantity PMA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }

  let(:claimed_quantity_deg) { "{\"dataElementGroups\":[{\"name\":\"Claimeds - Quantity PCA\",\"shortName\":\"claimed-Quantity PCA\",\"code\":\"claimed-Quantity PCA\",\"dataElements\":[{\"id\":\"cl-ext-1\"},{\"id\":\"cl-ext-2\"}]}]}" }
  let(:claimed_quantity_dataset) { "{\"dataSets\":[{\"name\":\"Claimeds - Quantity PCA\",\"shortName\":\"claimed-Quantity PCA\",\"code\":\"claimed-Quantity PCA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }
  let(:verified_quantity_deg) { "{\"dataElementGroups\":[{\"name\":\"Verifieds - Quantity PCA\",\"shortName\":\"verified-Quantity PCA\",\"code\":\"verified-Quantity PCA\",\"dataElements\":[]}]}" }
  let(:verified_quantity_dataset) { "{\"dataSets\":[{\"name\":\"Verifieds - Quantity PCA\",\"shortName\":\"verified-Quantity PCA\",\"code\":\"verified-Quantity PCA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }
  let(:tarif_quantity_deg) { "{\"dataElementGroups\":[{\"name\":\"Tarifs - Quantity PCA\",\"shortName\":\"tarif-Quantity PCA\",\"code\":\"tarif-Quantity PCA\",\"dataElements\":[{\"id\":\"tarif-ext-1\"},{\"id\":\"tarif-ext-2\"}]}]}" }
  let(:tarif_quantity_dataset) { "{\"dataSets\":[{\"name\":\"Tarifs - Quantity PCA\",\"shortName\":\"tarif-Quantity PCA\",\"code\":\"tarif-Quantity PCA\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }

  let(:claimed_quality_deg) { "{\"dataElementGroups\":[{\"name\":\"Claimeds - Quality\",\"shortName\":\"claimed-Quality\",\"code\":\"claimed-Quality\",\"dataElements\":[{\"id\":\"cl-ext-1\"},{\"id\":\"cl-ext-2\"}]}]}" }
  let(:claimed_quality_dataset) { "{\"dataSets\":[{\"name\":\"Claimeds - Quality\",\"shortName\":\"claimed-Quality\",\"code\":\"claimed-Quality\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }
  let(:verified_quality_deg) { "{\"dataElementGroups\":[{\"name\":\"Verifieds - Quality\",\"shortName\":\"verified-Quality\",\"code\":\"verified-Quality\",\"dataElements\":[]}]}" }
  let(:verified_quality_dataset) { "{\"dataSets\":[{\"name\":\"Verifieds - Quality\",\"shortName\":\"verified-Quality\",\"code\":\"verified-Quality\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }

  let(:maxscore_quality_deg) { "{\"dataElementGroups\":[{\"name\":\"Max. Scores - Quality\",\"shortName\":\"max_score-Quality\",\"code\":\"max_score-Quality\",\"dataElements\":[]}]}" }
  let(:maxscore_quality_dataset) { "{\"dataSets\":[{\"name\":\"Max. Scores - Quality\",\"shortName\":\"max_score-Quality\",\"code\":\"max_score-Quality\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }

  let(:claimed_perf_deg) { "{\"dataElementGroups\":[{\"name\":\"Claimeds - Performance Adm\",\"shortName\":\"claimed-Performance Adm\",\"code\":\"claimed-Performance Adm\",\"dataElements\":[{\"id\":\"cl-ext-1\"},{\"id\":\"cl-ext-2\"}]}]}" }
  let(:claimed_perf_dataset) { "{\"dataSets\":[{\"name\":\"Claimeds - Performance Adm\",\"shortName\":\"claimed-Performance Adm\",\"code\":\"claimed-Performance Adm\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }

  let(:max_score_perf_deg) { "{\"dataElementGroups\":[{\"name\":\"Max. Scores - Performance Adm\",\"shortName\":\"max_score-Performance Adm\",\"code\":\"max_score-Performance Adm\",\"dataElements\":[]}]}" }
  let(:max_score_perf_dataset) { "{\"dataSets\":[{\"name\":\"Max. Scores - Performance Adm\",\"shortName\":\"max_score-Performance Adm\",\"code\":\"max_score-Performance Adm\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }
  let(:budget_perf_deg) { "{\"dataElementGroups\":[{\"name\":\"Budgets - Performance Adm\",\"shortName\":\"budget-Performance Adm\",\"code\":\"budget-Performance Adm\",\"dataElements\":[]}]}" }
  let(:budget_perf_dataset) { "{\"dataSets\":[{\"name\":\"Budgets - Performance Adm\",\"shortName\":\"budget-Performance Adm\",\"code\":\"budget-Performance Adm\",\"periodType\":\"Monthly\",\"dataElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}" }
  let(:all_deg) do
    [claimed_deg, verified_deg,
     tarif_deg,
     claimed_quantity_deg,
     verified_quantity_deg,
     tarif_quantity_deg,
     claimed_quality_deg,
     verified_quality_deg,
     maxscore_quality_deg,
     claimed_perf_deg,
     max_score_perf_deg,
     budget_perf_deg]
  end

  let(:all_dataset) do
    [claimed_dataset,
     verified_dataset,
     tarif_dataset,
     claimed_quantity_dataset,
     verified_quantity_dataset,
     tarif_quantity_dataset,
     claimed_quality_dataset,
     verified_quality_dataset,
     maxscore_quality_dataset,
     claimed_perf_dataset,
     max_score_perf_dataset,
     budget_perf_dataset]
  end

  it "should create" do
    stub_all_indicators
    all_deg.each do |deg|
      stub_data_elements_groups_creation(deg)
      stub_find_data_element_group_by_name(deg)
    end
    stub_category_combos
    all_dataset.each do |ds|
      stub_create_dataset(ds)
      stub_find_dataset_by_name(ds)
      stub_update_data_element_sets
    end
    stub_data_elements_in_dataset("cl-ext-1")
    stub_data_elements_in_dataset("cl-ext-2")
    stub_data_elements_in_dataset("tarif-ext-1")
    stub_data_elements_in_dataset("tarif-ext-2")

    SynchroniseDegDsWorker.new.perform(project.project_anchor.id)
  end

  def stub_all_indicators
    stub_request(:get, "#{project.dhis2_url}/api/indicators?fields=:all&pageSize=50000")
      .to_return(status: 200, body: fixture_content(:dhis2, "indicators.json"))
  end

  def stub_data_elements_groups_creation(deg)
    stub_request(:post, "http://play.dhis2.org/demo/api/metadata")
      .with(body: deg)
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_update_data_element_sets
    stub_request(:put, "http://play.dhis2.org/demo/api/dataSets/")
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_find_data_element_group_by_name(deg)
    stub_request(:get, "http://play.dhis2.org/demo/api/dataElementGroups?fields=:all&filter=name:eq:#{JSON.parse(deg)['dataElementGroups'].first['name']}")
      .to_return(status: 200, body: deg)
  end

  def stub_category_combos
    stub_request(:get, "http://play.dhis2.org/demo/api/categoryCombos?fields=:all&filter=name:eq:default")
      .to_return(status: 200, body: fixture_content(:dhis2, "category_combos.json"))
  end

  def stub_create_dataset(dataset)
    stub_request(:post, "http://play.dhis2.org/demo/api/metadata")
      .with(body: dataset)
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_find_dataset_by_name(dataset)
    stub_request(:get, "http://play.dhis2.org/demo/api/dataSets?fields=:all&filter=name:eq:#{JSON.parse(dataset)['dataSets'].first['name']}")
      .to_return(status: 200, body: dataset)
  end

  def stub_data_elements_in_dataset(id)
    stub_request(:post, "http://play.dhis2.org/demo/api/dataSets//dataElements/#{id}")
      .to_return(status: 200, body: "", headers: {})
  end
end
