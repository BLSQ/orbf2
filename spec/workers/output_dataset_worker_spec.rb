require "rails_helper"
require_relative "./dhis2_snapshot_fixture"
require_relative "dhis2_stubs"

RSpec.describe OutputDatasetWorker do
  include Dhis2SnapshotFixture
  include Dhis2Stubs
  include_context "basic_context"

  let(:program) { create :program }

  let!(:project) do
    project = full_project
    project.save!
    user.save!
    user.program = program

    project.payment_rules.last.destroy!
    project.packages[1].destroy!
    project.packages[-1].destroy!
    project.reload
    project.entity_group.update!(external_reference: "GGghZsfu7qV")

    project
  end

  let(:worker) { described_class.new }

  let(:payment_rule) { project.payment_rules.first }

  it "create dataset" do
    stub_snapshots(project)

    stub_default_category_success
    stub_create_dataset
    stub_find_by_name
    stub_update

    worker.perform(project.id, payment_rule.code, "quarterly", "modes" => "create")
  end

  def stub_create_dataset
    stub_request(:post, "http://play.dhis2.org/demo/api/metadata")
      .with(body: "{\"dataSets\":[{\"name\":\"ORBF - Payment rule pma - Quarterly\",\"shortName\":\"ORBF - Payment rule pma - Quarterly\",\"code\":null,\"periodType\":\"Quarterly\",\"dataElements\":[{\"id\":\"ext-attributed_points\"},{\"id\":\"ext-max_points\"},{\"id\":\"ext-quality_technical_score_value\"}],\"organisationUnits\":[{\"id\":\"vRC0stJ5y9Q\"},{\"id\":\"bM4Ky73uMao\"},{\"id\":\"cgqkFdShPzg\"},{\"id\":\"kLNQT4KQ9hT\"},{\"id\":\"kMTHqMgenme\"},{\"id\":\"wNYYRm2c9EK\"},{\"id\":\"Bq5nb7UAEGd\"},{\"id\":\"T2Cn45nBY0u\"},{\"id\":\"roQ2l7TX0eZ\"},{\"id\":\"JNJIPX9DfaW\"},{\"id\":\"nCh5dBoJVNw\"},{\"id\":\"vv1QJFONsT6\"},{\"id\":\"jCnyQOKQBFX\"},{\"id\":\"OuwX8H2CcRO\"},{\"id\":\"uNEhNuBUr0i\"},{\"id\":\"IXJg79fclDm\"},{\"id\":\"mTNOoGXuC39\"},{\"id\":\"NnQpISrLYWZ\"},{\"id\":\"GQcsUZf81vP\"},{\"id\":\"xmZNDeO0qCR\"},{\"id\":\"jk1TtiBM5hz\"},{\"id\":\"uROAmk9ymNE\"},{\"id\":\"cdmkMyYv04T\"},{\"id\":\"taKiTcaf05H\"},{\"id\":\"ctN0WgIvfke\"},{\"id\":\"bqtZrXoryDF\"},{\"id\":\"Tht0fnjagHi\"},{\"id\":\"JCXEtUDYyp9\"}],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"},\"openFuturePeriods\":3}]}")
      .to_return(status: 200, body: "")
  end

  def stub_find_by_name
    stub_request(:get, "http://play.dhis2.org/demo/api/dataSets?fields=:all&filter=name:eq:ORBF%20-%20Payment%20rule%20pma%20-%20Quarterly")
      .to_return(status: 200, body: "{\"dataSets\":[{\"id\":\"uuiddataset\", \"name\":\"ORBF - Payment rule pma - Quarterly\",\"shortName\":\"ORBF - Payment rule pma - Quarterly\",\"code\":null,\"periodType\":\"Quarterly\",\"dataSetElements\":[],\"organisationUnits\":[],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"}}]}")
  end

  def stub_update
    stub_request(:put, "http://play.dhis2.org/demo/api/dataSets/uuiddataset")
      .with(body: "{\"id\":\"uuiddataset\",\"name\":\"ORBF - Payment rule pma - Quarterly\",\"shortName\":\"ORBF - Payment rule pma - Quarterly\",\"code\":null,\"periodType\":\"Quarterly\",\"dataSetElements\":[{\"dataElement\":{\"id\":\"ext-quality_technical_score_value\"}},{\"dataElement\":{\"id\":\"ext-max_points\"}},{\"dataElement\":{\"id\":\"ext-attributed_points\"}}],\"organisationUnits\":[{\"id\":\"Bq5nb7UAEGd\"},{\"id\":\"GQcsUZf81vP\"},{\"id\":\"IXJg79fclDm\"},{\"id\":\"JCXEtUDYyp9\"},{\"id\":\"JNJIPX9DfaW\"},{\"id\":\"NnQpISrLYWZ\"},{\"id\":\"OuwX8H2CcRO\"},{\"id\":\"T2Cn45nBY0u\"},{\"id\":\"Tht0fnjagHi\"},{\"id\":\"bM4Ky73uMao\"},{\"id\":\"bqtZrXoryDF\"},{\"id\":\"cdmkMyYv04T\"},{\"id\":\"cgqkFdShPzg\"},{\"id\":\"ctN0WgIvfke\"},{\"id\":\"jCnyQOKQBFX\"},{\"id\":\"jk1TtiBM5hz\"},{\"id\":\"kLNQT4KQ9hT\"},{\"id\":\"kMTHqMgenme\"},{\"id\":\"mTNOoGXuC39\"},{\"id\":\"nCh5dBoJVNw\"},{\"id\":\"roQ2l7TX0eZ\"},{\"id\":\"taKiTcaf05H\"},{\"id\":\"uNEhNuBUr0i\"},{\"id\":\"uROAmk9ymNE\"},{\"id\":\"vRC0stJ5y9Q\"},{\"id\":\"vv1QJFONsT6\"},{\"id\":\"wNYYRm2c9EK\"},{\"id\":\"xmZNDeO0qCR\"}],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"},\"displayName\":\"ORBF - Payment rule pma - Quarterly\"}")
      .to_return(status: 200, body: "")
    stub_request(:put, "http://play.dhis2.org/demo/api/dataSets/uuiddataset")
      .with(body: "{\"id\":\"uuiddataset\",\"name\":\"ORBF - Payment rule pma - Quarterly\",\"shortName\":\"ORBF - Payment rule pma - Quarterly\",\"code\":null,\"periodType\":\"Quarterly\",\"dataSetElements\":[{\"dataElement\":{\"id\":\"ext-attributed_points\"}},{\"dataElement\":{\"id\":\"ext-max_points\"}},{\"dataElement\":{\"id\":\"ext-quality_technical_score_value\"}}],\"organisationUnits\":[{\"id\":\"Bq5nb7UAEGd\"},{\"id\":\"GQcsUZf81vP\"},{\"id\":\"IXJg79fclDm\"},{\"id\":\"JCXEtUDYyp9\"},{\"id\":\"JNJIPX9DfaW\"},{\"id\":\"NnQpISrLYWZ\"},{\"id\":\"OuwX8H2CcRO\"},{\"id\":\"T2Cn45nBY0u\"},{\"id\":\"Tht0fnjagHi\"},{\"id\":\"bM4Ky73uMao\"},{\"id\":\"bqtZrXoryDF\"},{\"id\":\"cdmkMyYv04T\"},{\"id\":\"cgqkFdShPzg\"},{\"id\":\"ctN0WgIvfke\"},{\"id\":\"jCnyQOKQBFX\"},{\"id\":\"jk1TtiBM5hz\"},{\"id\":\"kLNQT4KQ9hT\"},{\"id\":\"kMTHqMgenme\"},{\"id\":\"mTNOoGXuC39\"},{\"id\":\"nCh5dBoJVNw\"},{\"id\":\"roQ2l7TX0eZ\"},{\"id\":\"taKiTcaf05H\"},{\"id\":\"uNEhNuBUr0i\"},{\"id\":\"uROAmk9ymNE\"},{\"id\":\"vRC0stJ5y9Q\"},{\"id\":\"vv1QJFONsT6\"},{\"id\":\"wNYYRm2c9EK\"},{\"id\":\"xmZNDeO0qCR\"}],\"categoryCombo\":{\"id\":\"p0KPaWEg3cf\",\"name\":\"default\"},\"displayName\":\"ORBF - Payment rule pma - Quarterly\"}")
      .to_return(status: 200, body: "", headers: {})
  end
end
