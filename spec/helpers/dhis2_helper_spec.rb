# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dhis2Helper, type: :helper do
  let(:project) { double(dhis2_url: "https://sample.org/dhis2") }

  it "links to dhis2 dataset" do
    expect(helper.link_to_dataset(project, "dsid")).to eq(
      '<a target="_blank" class="external" '\
        'href="https://sample.org/dhis2/dhis-web-maintenance/#/edit/dataSetSection/dataSet/dsid">dsid</a>'
    )
  end

  it "links to dhis2 indicator" do
    expect(helper.link_to_indicator(project, "dsid")).to eq(
      '<a target="_blank" class="external" '\
        'href="https://sample.org/dhis2/dhis-web-maintenance/#/edit/indicatorSection/indicator/dsid">dsid</a>'
    )
  end

  it "links to dhis2 data elements" do
    expect(helper.link_to_data_element(project, "dsid")).to eq(
      '<a target="_blank" class="external" '\
        'href="https://sample.org/dhis2/dhis-web-maintenance/#/edit/dataElementSection/dataElement/dsid">dsid</a>'
    )
  end

  it "links to dhis2 cocs" do
    expect(helper.link_to_coc(project, "dsid")).to eq(
      '<a target="_blank" class="external" '\
        'href="https://sample.org/dhis2/dhis-web-maintenance/#/edit/categorySection/categoryOptionCombo/dsid">dsid</a>'
    )
  end


end
