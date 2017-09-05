module Invoicing
  class EntityBuilder
    def to_entity(org_unit)
      Analytics::Entity.new(
        org_unit.id,
        org_unit.name,
        to_group_ids(org_unit),
        to_facts(org_unit)
      )
    end

    private

    def to_group_ids(org_unit)
      org_unit.organisation_unit_groups.map { |n| n["id"] }
    end

    def to_code(dhis2_ressource)
      code = dhis2_ressource.code || dhis2_ressource.short_name || dhis2_ressource.display_name
      Codifier.codify(code)
    end

    def to_facts(org_unit)
      parent_ids = org_unit.path.split("/").reject(&:empty?)
      facts = parent_ids.each_with_index
                        .map { |parent_id, index| ["level_#{index + 1}", parent_id] }
                        .to_h
      facts.merge(to_group_set_facts(org_unit))
    end

    def to_group_set_facts(org_unit)
      pyramid = org_unit.pyramid
      group_set_facts = pyramid.org_unit_groups(to_group_ids(org_unit))
                               .flat_map do |group|
        next unless group
        group.group_set_ids.map do |groupset_id|
          groupset = pyramid.org_unit_group_set(groupset_id)
          ["groupset_code_#{to_code(groupset)}", to_code(group)]
        end
      end
      group_set_facts.compact.reject(&:empty?).to_h
    end
  end
end
