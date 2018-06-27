
module Datasets
  class ToDhis2Datasets
    attr_reader :dataset

    def initialize(dataset)
      @dataset = dataset
    end

    def call
      name = dataset_name
      dataset_info = dataset.dataset_info
      {
        name:                  name,
        short_name:            name,
        period_type:           dataset_info.frequency.humanize,
        open_future_periods:   3,
        data_element_ids:      dataset_info.data_elements.sort,
        data_set_elements:     dataset_info.data_elements.sort.map do |de_id|
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
        dataset.frequency.humanize
      ].join(" - ")
    end
  end
end
