# frozen_string_literal: true

def to_dhis2_frequency(hesabu_frequency)
  hesabu_frequency.titleize.gsub(" ","")
end

module Datasets
  class ToDhis2Datasets
    attr_reader :dataset

    def initialize(dataset)
      @dataset = dataset
    end

    def call
      name = dataset_name
      dataset_info = dataset.dataset_info
      data_elements = dataset_info.data_elements.sort
      {
        name:                  name,
        short_name:            name,
        period_type:           to_dhis2_frequency(dataset_info.frequency),
        open_future_periods:   3,
        data_elements:         data_elements.map do |de_id|
          {
            "id": de_id
          }
        end,
        data_element_ids:      data_elements.sort,
        data_set_elements:     data_elements.map do |de_id|
                                 {
                                   "dataElement": {
                                     "id": de_id
                                   }
                                 }
                               end,
        organisation_unit_ids: dataset_info.orgunits.compact.map(&:ext_id)
      }
    end

    def dataset_name
      [
        "ORBF",
        dataset.payment_rule.rule.name,
        to_dhis2_frequency(dataset.frequency)
      ].join(" - ")
    end
  end
end
