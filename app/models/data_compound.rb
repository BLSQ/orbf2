class DataCompound
  def initialize(data_elements, data_elements_groups, indicators, category_combos)
    @data_elements_by_id = data_elements.index_by(&:id)
    @data_elements_groups_by_id = data_elements_groups.index_by(&:id)
    @indicators_by_id = indicators.index_by(&:id)
    @category_combos_by_id = category_combos ? category_combos.index_by(&:id) : {}

    data_elements_by_group = {}
    data_elements.each do |de|
      next unless de.data_element_groups

      de.data_element_groups.each do |group|
        data_elements_by_group[group["id"]] ||= Set.new
        data_elements_by_group[group["id"]].add(de)
      end
    end
    @data_elements_by_group = data_elements_by_group
  end

  def self.from(project)
    date = Time.now.utc.to_date
    data_compound = project.project_anchor.latest_data_compound
    return data_compound if data_compound

    dhis2 = project.dhis2_connection
    data_elements = dhis2.data_elements.list(fields: ":all", page_size: Dhis2SnapshotWorker::PAGE_SIZE)
    data_element_groups = dhis2.data_element_groups.list(fields: ":all", page_size: Dhis2SnapshotWorker::PAGE_SIZE)
    indicators = dhis2.indicators.list(fields: ":all", page_size: Dhis2SnapshotWorker::PAGE_SIZE)
    DataCompound.new(data_elements, data_element_groups, indicators, [])
  end

  def indicators(ids = nil)
    ids ? ids.map { |id| @indicators_by_id[id] } : @indicators_by_id.values
  end

  def indicator(id)
    @indicators_by_id[id]
  end

  def data_element(id)
    @data_elements_by_id[id]
  end

  def data_elements_from_group(group_id)
    @data_elements_by_group[group_id]
  end

  def data_elements
    @data_elements_by_id.values
  end

  def data_element_groups
    @data_elements_groups_by_id.values
  end

  def data_element_group(id)
    @data_elements_groups_by_id[id]
  end

  def category_combo(id)
    @category_combos_by_id[id]
  end

  def category_combos
    @category_combos_by_id.values
  end

  def category_option_combos_by_id
    @category_option_combos_by_id ||= category_combos.flat_map { |cc| cc["category_option_combos"] }.index_by { |coc| coc["id"] }
  end

  def category_option_combo(id)
    category_option_combos_by_id[id]
  end
end
