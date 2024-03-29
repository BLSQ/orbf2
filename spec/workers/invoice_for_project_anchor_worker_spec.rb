# frozen_string_literal: true

require "rails_helper"

require_relative "./project_fixture"
RSpec.describe InvoiceForProjectAnchorWorker do
  include ProjectFixture
  ORG_UNIT_ID = "vRC0stJ5y9Q"
  include_context "basic_context"
  let(:program) { create :program }

  let!(:project) do
    project = full_project
    project.save!
    project.update_attributes(read_through_deg: false)
    user.save!
    user.program = program

    with_activities_and_formula_mappings(project)
    create_snaphots(project)
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!
    project
  end
  let(:worker) { described_class.new }

  describe "throttled" do
    it "defaults to 3 concurrent" do
      expect(Sidekiq::Throttled::Registry.get(InvoiceForProjectAnchorWorker).concurrency.limit).to eq(3)
    end

    it "can be overridden with env" do
      skip("The `load` resets the code coverage, this test will pass but code coverage is incorrect")
      current_env = ENV["SDKQ_MAX_CONCURRENT_INVOICE"]
      ENV["SDKQ_MAX_CONCURRENT_INVOICE"] = "10"
      # Force a reload of the file to update throttled settings
      load File.join(Rails.root, "app/workers/invoice_for_project_anchor_worker.rb")
      expect(Sidekiq::Throttled::Registry.get(InvoiceForProjectAnchorWorker).concurrency.limit).to eq(10)
      if current_env
        ENV["SDKQ_MAX_CONCURRENT_INVOICE"] = current_env
      else
        ENV.delete("SDKQ_MAX_CONCURRENT_INVOICE")
      end
    end
  end

  it "should NOT on non contracted entities" do
    project.entity_group.external_reference = "gzcv65VyaGq"
    project.entity_group.save!

    fetch_values_request = stub_dhis2_values
    export_request = stub_request(:post, "http://play.dhis2.org/demo/api/dataValueSets")

    worker.perform(project.project_anchor.id, 2015, 1, ["Rp268JB6Ne4"])

    expect(fetch_values_request).to have_been_made.times(0)
    expect(export_request).to have_been_made.times(0)
  end

  it "should perform for subset of contracted_entities" do
    invoicing_job = project.project_anchor.invoicing_jobs.find_or_initialize_by(
      project_anchor_id: project.project_anchor.id,
      dhis2_period:      "2015Q1",
      orgunit_ref:       ORG_UNIT_ID
    )

    invoicing_job.update(
      status:          "enqueued",
      sidekiq_job_ref: "job_id"
    )

    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&orgUnit=vRC0stJ5y9Q&period=2015Q1")
      .to_return(status: 200, body: "", headers: {})

    export_request = stub_export_values("invoice_zero_new.json")
    worker.instance_variable_set(:@jid, "fakeJid123")
    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

    expect(export_request).to have_been_made.once

    expect(Dhis2Log.last.invoicing_job_id).to eq(invoicing_job.id)
    expect(Dhis2Log.last.sidekiq_job_ref).to eq("fakeJid123")
  end

  it "should perform for packages and payments quarterly" do
    project.payment_rules.each { |p| p.update(frequency: "quarterly") }
    project.packages.each { |p| p.update(frequency: "quarterly") }
    project.packages.first.package_states.first.update(ds_external_reference: "dataset")
    with_activities_and_formula_mappings(project)

    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&dataSet=dataset&orgUnit=vRC0stJ5y9Q&period=2015Q1")
      .to_return(status: 200, body: JSON.pretty_generate("dataValues": generate_quarterly_values_for(project)))

    export_request = stub_export_values("invoice_quarterly.json")

    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

    expect(export_request).to have_been_made.once
  end

  it "should support formula with parent levels" do
    population_state = project.states.create!(name: "population")
    package = project.packages.first
    package.states.push(population_state)
    formula = package.activity_rule.formulas.create(
      code:        "sample_parent_values",
      description: "sample_parent_values",
      expression:  "verified / population_level_1"
    )
    with_activities_and_formula_mappings(project)

    org_unit_values = generate_quarterly_values_for(project)

    refs = project.activities
                  .flat_map(&:activity_states)
                  .select { |activity_state| activity_state.state == population_state }
                  .map(&:external_reference)
                  .uniq
                  .reject(&:empty?).sort

    org_unit_level_1_values = refs.map do |external_reference|
      {
        dataElement:          external_reference,
        value:                123,
        period:               "2015",
        orgUnit:              "ImspTQPwCqd",
        categoryOptionCombo:  "HllvX50cXC0",
        attributeOptionCombo: "HllvX50cXC0"
      }
    end

    project.packages.first.package_states.first.update(ds_external_reference: "dataset")

    Rails.logger.info "org_unit_level_1_values #{org_unit_level_1_values.to_json}"
    value_request = stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&dataSet=dataset&orgUnit=vRC0stJ5y9Q&period=2015Q1")
                    .to_return(status: 200, body: JSON.pretty_generate("dataValues": (org_unit_values + org_unit_level_1_values)))

    export_request = stub_export_values("invoice_with_parent.json")

    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])
    expect(value_request).to have_been_made.once
    expect(export_request).to have_been_made.once
  end

  it "should perform for sub contracted entities pattern" do
    with_multi_entity_rule(project)
    with_activities_and_formula_mappings(project)

    expect(project.packages.first.activity_rule.available_variables).to include(
      "org_units_count",
      "org_units_sum_if_count"
    )

    refs = project.activities
                  .flat_map(&:activity_states)
                  .map(&:external_reference)
                  .uniq
                  .reject(&:empty?).sort
    values = refs.each_with_index.flat_map do |data_element, index|
      [{
        dataElement:          data_element,
        value:                index,
        period:               "2015",
        orgUnit:              ORG_UNIT_ID,
        categoryOptionCombo:  "HllvX50cXC0",
        attributeOptionCombo: "HllvX50cXC0"
      }, (1..12).map do |month|
        {
          dataElement:          data_element,
          value:                index,
          period:               "2015#{month}",
          orgUnit:              ORG_UNIT_ID,
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }
      end, (1..12).map do |month|
        {
          dataElement:          data_element,
          value:                index,
          period:               "2015#{month}",
          orgUnit:              "PMa2VCrupOd",
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }
      end]
    end

    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&dataSet=ds-0&dataSet=ds-1&dataSet=ds-2&orgUnit=AhnK8hb3JWm&orgUnit=BLVKubgVxkF&orgUnit=Bift1B4gjru&orgUnit=Bq5nb7UAEGd&orgUnit=C9uduqDZr9d&orgUnit=DSBXsRQSXUW&orgUnit=DmaLM8WYmWv&orgUnit=ENHOJz3UH5L&orgUnit=Ea3j0kUvyWg&orgUnit=EmTN0L4EAVi&orgUnit=GvFqTavdpGE&orgUnit=HPg74Rr7UWp&orgUnit=IXJg79fclDm&orgUnit=ImspTQPwCqd&orgUnit=JLKGG67z7oj&orgUnit=JNJIPX9DfaW&orgUnit=KIUCimTXf8Q&orgUnit=KKkLOTpMXGV&orgUnit=KuR0y0h0mOM&orgUnit=LV2b3vaLRl1&orgUnit=LaxJ6CD2DHq&orgUnit=Ls2ESQONh9S&orgUnit=M2qEv692lS6&orgUnit=M721NHGtdZV&orgUnit=O6uvpzGd5pu&orgUnit=OuwX8H2CcRO&orgUnit=PD1fqyvJssC&orgUnit=PLoeN9CaL7z&orgUnit=PMa2VCrupOd&orgUnit=PQZJPIpTepd&orgUnit=Qw7c6Ckb0XC&orgUnit=QywkxFudXrC&orgUnit=RUCp6OaTSAD&orgUnit=T2Cn45nBY0u&orgUnit=TEQlaapDQoK&orgUnit=TQkG0sX9nca&orgUnit=U6Kr7Gtpidn&orgUnit=Uo4cyJwAhTW&orgUnit=VCtF1DbspR5&orgUnit=VGAFxBXz16y&orgUnit=Vnc2qIRLbyw&orgUnit=Vth0fbpFcsO&orgUnit=W5fN3G6y1VI&orgUnit=XEyIRFd9pct&orgUnit=XJ6DqDkMlPv&orgUnit=at6UHUQatSo&orgUnit=bM4Ky73uMao&orgUnit=bPHn9IgjKLC&orgUnit=bVZTNrnfn9G&orgUnit=cDw53Ej8rju&period=2014July&period=2015&period=201501&period=201502&period=201503&period=2015Q1")
      .to_return(status: 200, body: JSON.pretty_generate("dataValues": values.flatten))

    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&dataSet=ds-0&dataSet=ds-1&dataSet=ds-2&orgUnit=cM2BKSrj9F9&orgUnit=cZtKKa9eJZ3&orgUnit=cgqkFdShPzg&orgUnit=ctfiYW0ePJ8&orgUnit=eIQbndfxQMb&orgUnit=fXT1scbEObM&orgUnit=fdc6uOvgoji&orgUnit=gmen7SXL9CU&orgUnit=jCnyQOKQBFX&orgUnit=jUb8gELQApl&orgUnit=jmIPBj66vD6&orgUnit=kBP1UvZpsNj&orgUnit=kJq2mPyFEHo&orgUnit=kLNQT4KQ9hT&orgUnit=kMTHqMgenme&orgUnit=lc3eMKXaEfw&orgUnit=mTNOoGXuC39&orgUnit=nCh5dBoJVNw&orgUnit=nV3OkyzF4US&orgUnit=nq7F0t1Pz6t&orgUnit=qhqAxPSTUXp&orgUnit=qtr8GGlm4gg&orgUnit=roQ2l7TX0eZ&orgUnit=tHUYjt9cU6h&orgUnit=u6ZGNI8yUmt&orgUnit=uNEhNuBUr0i&orgUnit=vRC0stJ5y9Q&orgUnit=vn9KJsLyP5f&orgUnit=vv1QJFONsT6&orgUnit=wNYYRm2c9EK&orgUnit=wicmjKI3xiP&orgUnit=yP2nhllbQPh&period=2014July&period=2015&period=201501&period=201502&period=201503&period=2015Q1")
      .to_return(status: 200, body: JSON.pretty_generate("dataValues": values.flatten))

    export_request = stub_export_values("invoice_multi_entities.json")

    worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

    expect(export_request).to have_been_made.once
  end

  describe "new engine" do
    let(:org_unit_ids) do
      %w[AhnK8hb3JWm BLVKubgVxkF Bift1B4gjru Bq5nb7UAEGd C9uduqDZr9d DSBXsRQSXUW DmaLM8WYmWv ENHOJz3UH5L Ea3j0kUvyWg EmTN0L4EAVi GvFqTavdpGE HPg74Rr7UWp IXJg79fclDm ImspTQPwCqd JLKGG67z7oj JNJIPX9DfaW KIUCimTXf8Q KKkLOTpMXGV KuR0y0h0mOM LV2b3vaLRl1 LaxJ6CD2DHq Ls2ESQONh9S M2qEv692lS6 M721NHGtdZV O6uvpzGd5pu OuwX8H2CcRO PD1fqyvJssC PLoeN9CaL7z PMa2VCrupOd PQZJPIpTepd Qw7c6Ckb0XC QywkxFudXrC RUCp6OaTSAD T2Cn45nBY0u TEQlaapDQoK TQkG0sX9nca U6Kr7Gtpidn Uo4cyJwAhTW VCtF1DbspR5 VGAFxBXz16y Vnc2qIRLbyw Vth0fbpFcsO W5fN3G6y1VI XEyIRFd9pct XJ6DqDkMlPv at6UHUQatSo bM4Ky73uMao bPHn9IgjKLC bVZTNrnfn9G cDw53Ej8rju cM2BKSrj9F9 cZtKKa9eJZ3 cgqkFdShPzg ctfiYW0ePJ8 eIQbndfxQMb fXT1scbEObM fdc6uOvgoji gmen7SXL9CU jCnyQOKQBFX jUb8gELQApl jmIPBj66vD6 kBP1UvZpsNj kJq2mPyFEHo kLNQT4KQ9hT kMTHqMgenme lc3eMKXaEfw mTNOoGXuC39 nCh5dBoJVNw nV3OkyzF4US nq7F0t1Pz6t qhqAxPSTUXp qtr8GGlm4gg roQ2l7TX0eZ tHUYjt9cU6h u6ZGNI8yUmt uNEhNuBUr0i vRC0stJ5y9Q vn9KJsLyP5f vv1QJFONsT6 wNYYRm2c9EK wicmjKI3xiP yP2nhllbQPh]
    end
    let(:dataset_ext_ids) { ["ds-0", "ds-1", "ds-2"] }
    let(:periods) { %w[2014July 2015 201501 201502 201503 2015Q1] }

    it "should perform for sub contracted entities pattern with new engine" do
      with_new_engine(project)

      with_multi_entity_rule(project)
      with_activities_and_formula_mappings(project)

      expect(project.packages.first.activity_rule.available_variables).to include(
        "org_units_count",
        "org_units_sum_if_count"
      )

      refs = project.activities
                    .flat_map(&:activity_states)
                    .map(&:external_reference)
                    .uniq
                    .reject(&:empty?).sort
      values = refs.each_with_index.flat_map do |data_element, index|
        [{
          dataElement:          data_element,
          value:                index,
          period:               "2015",
          orgUnit:              ORG_UNIT_ID,
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }, (1..12).map do |month|
          {
            dataElement:          data_element,
            value:                index,
            period:               "2015#{month}",
            orgUnit:              ORG_UNIT_ID,
            categoryOptionCombo:  "HllvX50cXC0",
            attributeOptionCombo: "HllvX50cXC0"
          }
        end, (1..12).map do |month|
          {
            dataElement:          data_element,
            value:                index,
            period:               "2015#{month}",
            orgUnit:              "PMa2VCrupO",
            categoryOptionCombo:  "HllvX50cXC0",
            attributeOptionCombo: "HllvX50cXC0"
          }
        end]
      end

      org_unit_ids.each_slice(50).each do |org_unit_ids_slice|
        orgunit_values = values.flatten.select { |v| org_unit_ids_slice.include?(v[:orgUnit]) }
        stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?" +
          dataset_ext_ids.each_with_index.map { |de, i| "#{i == 0 ? '' : '&'}dataSet=#{de}" }.join +
          periods.map { |pe| "&period=#{pe}" }.join +
          org_unit_ids_slice.map { |id| "&orgUnit=#{id}" }.join +
          "&children=false")
          .to_return(status: 200, body: JSON.pretty_generate("dataValues": orgunit_values))
      end

      export_request = stub_export_values("invoice_multi_entities_new_engine.json")

      worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

      expect(export_request).to have_been_made.once
    end
  end

  describe "new engine" do
    let(:org_unit_ids) do
      %w[AhnK8hb3JWm BLVKubgVxkF Bift1B4gjru Bq5nb7UAEGd C9uduqDZr9d DSBXsRQSXUW DmaLM8WYmWv ENHOJz3UH5L Ea3j0kUvyWg EmTN0L4EAVi GvFqTavdpGE HPg74Rr7UWp IXJg79fclDm ImspTQPwCqd JLKGG67z7oj JNJIPX9DfaW KIUCimTXf8Q KKkLOTpMXGV KuR0y0h0mOM LV2b3vaLRl1 LaxJ6CD2DHq Ls2ESQONh9S M2qEv692lS6 M721NHGtdZV O6uvpzGd5pu OuwX8H2CcRO PD1fqyvJssC PLoeN9CaL7z PMa2VCrupOd PQZJPIpTepd Qw7c6Ckb0XC QywkxFudXrC RUCp6OaTSAD T2Cn45nBY0u TEQlaapDQoK TQkG0sX9nca U6Kr7Gtpidn Uo4cyJwAhTW VCtF1DbspR5 VGAFxBXz16y Vnc2qIRLbyw Vth0fbpFcsO W5fN3G6y1VI XEyIRFd9pct XJ6DqDkMlPv at6UHUQatSo bM4Ky73uMao bPHn9IgjKLC bVZTNrnfn9G cDw53Ej8rju cM2BKSrj9F9 cZtKKa9eJZ3 cgqkFdShPzg ctfiYW0ePJ8 eIQbndfxQMb fXT1scbEObM fdc6uOvgoji gmen7SXL9CU jCnyQOKQBFX jUb8gELQApl jmIPBj66vD6 kBP1UvZpsNj kJq2mPyFEHo kLNQT4KQ9hT kMTHqMgenme lc3eMKXaEfw mTNOoGXuC39 nCh5dBoJVNw nV3OkyzF4US nq7F0t1Pz6t qhqAxPSTUXp qtr8GGlm4gg roQ2l7TX0eZ tHUYjt9cU6h u6ZGNI8yUmt uNEhNuBUr0i vRC0stJ5y9Q vn9KJsLyP5f vv1QJFONsT6 wNYYRm2c9EK wicmjKI3xiP yP2nhllbQPh]
    end
    let(:dataset_ext_ids) { ["ds-0", "ds-1", "ds-2"] }
    let(:periods) { %w[2014July 2015 201501 201502 201503 2015Q1] }

    it "should perform for sub contracted entities pattern with new engine" do
      with_latest_engine(project)

      with_multi_entity_rule(project)
      with_activities_and_formula_mappings(project)

      expect(project.packages.first.activity_rule.available_variables).to include(
        "org_units_count",
        "org_units_sum_if_count"
      )

      refs = project.activities
                    .flat_map(&:activity_states)
                    .map(&:external_reference)
                    .uniq
                    .reject(&:empty?).sort
      values = refs.each_with_index.flat_map do |data_element, index|
        [{
          dataElement:          data_element,
          value:                index,
          period:               "2015",
          orgUnit:              ORG_UNIT_ID,
          categoryOptionCombo:  "HllvX50cXC0",
          attributeOptionCombo: "HllvX50cXC0"
        }, (1..12).map do |month|
          {
            dataElement:          data_element,
            value:                index,
            period:               "2015#{month}",
            orgUnit:              ORG_UNIT_ID,
            categoryOptionCombo:  "HllvX50cXC0",
            attributeOptionCombo: "HllvX50cXC0"
          }
        end, (1..12).map do |month|
          {
            dataElement:          data_element,
            value:                index,
            period:               "2015#{month}",
            orgUnit:              "PMa2VCrupO",
            categoryOptionCombo:  "HllvX50cXC0",
            attributeOptionCombo: "HllvX50cXC0"
          }
        end]
      end

      org_unit_ids.each_slice(50).each do |org_unit_ids_slice|
        orgunit_values = values.flatten.select { |v| org_unit_ids_slice.include?(v[:orgUnit]) }
        stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?" +
          dataset_ext_ids.each_with_index.map { |de, i| "#{i == 0 ? '' : '&'}dataSet=#{de}" }.join +
          periods.map { |pe| "&period=#{pe}" }.join +
          org_unit_ids_slice.map { |id| "&orgUnit=#{id}" }.join +
          "&children=false")
          .to_return(status: 200, body: JSON.pretty_generate("dataValues": orgunit_values))
      end

      export_request = stub_export_values("invoice_multi_entities_new_engine_v3.json")

      worker.perform(project.project_anchor.id, 2015, 1, [ORG_UNIT_ID])

      expect(export_request).to have_been_made.once
    end
  end

  describe "retry logic" do
    it "doesn't fail if equation fails" do
      expect(InvoicingJob).to receive(:execute) { raise Hesabu::Error.new("In equation and so on")}
      expect {
        worker.perform(project.project_anchor.id, 2015, 1, ["Rp268JB6Ne4"])
      }.to_not raise_error
    end

    it 'fails if hesabu error other than equation fails' do
      expect(InvoicingJob).to receive(:execute) { raise Hesabu::Error.new("Some error in Hesabu")}

      expect {
        worker.perform(project.project_anchor.id, 2015, 1, ["Rp268JB6Ne4"])
      }.to raise_error(Hesabu::Error, "Some error in Hesabu")
    end
  end
  def stub_dhis2_values_yearly(values, start_date)
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&endDate=2015-12-31&orgUnit=vRC0stJ5y9Q&startDate=#{start_date}")
      .to_return(status: 200, body: values)
  end

  def stub_dhis2_values(values = "")
    stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?children=false&endDate=2015-12-31&orgUnit=vRC0stJ5y9Q&startDate=2015-01-01")
      .to_return(status: 200, body: values)
  end

  def stub_export_values(expected_fixture)
    Rails.logger.info "Stubbing dataValueSets with #{expected_fixture}"
    stub_request(:post, "http://play.dhis2.org/demo/api/dataValueSets")
      .with { |request|
      fixture_values = sorted_datavalues(JSON.parse(fixture_content(:scorpio, expected_fixture)))
      values = sorted_datavalues(JSON.parse(request.body))
      fixture_values == values
    }
      .to_return(status: 200, body: "")
  end

  def sorted_datavalues(json)
    sorted = json["dataValues"].sort_by { |e| [e["dataElement"], e["orgUnit"], e["period"]] }
    # Rails.logger.info "sorted\n #{sorted}\n\n\n"
    sorted
  end
end
