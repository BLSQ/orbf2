
module Invoicing
  class EntitySignalitic
    def initialize(pyramid, org_unit_id)
      @pyramid = pyramid
      @org_unit_id = org_unit_id
      @org_unit = build_org_unit_with_facts
    end

    def call
      [
        org_unit.name,
        "Path : " + parents.map(&:name).join(" > "),
        "Groups : " + groups.map(&:name).join(", "),
        "Facts : " + org_unit.facts.map(&:to_s).join(", ")
      ]
    end

    attr_reader :org_unit_id, :pyramid, :org_unit

    def parents
      org_unit.parent_ext_ids.map { |parent_id| pyramid.org_unit(parent_id) }
    end

    def groups
      pyramid.groups(org_unit.group_ext_ids)
    end

    def build_org_unit_with_facts
      raw_org_unit = pyramid.org_unit(org_unit_id)
      Orbf::RulesEngine::OrgUnitWithFacts.new(
        orgunit: raw_org_unit,
        facts:   Orbf::RulesEngine::OrgunitFacts.new(raw_org_unit, pyramid).to_facts
      )
    end
  end
end
