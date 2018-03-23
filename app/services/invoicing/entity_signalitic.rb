
module Invoicing
  class EntitySignalitic
    def initialize(pyramid, org_unit_id)
      @pyramid = pyramid
      @org_unit_id = org_unit_id
    end

    def call
      [
        org_unit.name,
        "Path : " + org_unit.parent_ext_ids.map { |parent_id| pyramid.org_unit(parent_id) }.map(&:name).join(" > "),
        "Groups : " + pyramid.groups(org_unit.group_ext_ids).map(&:name).join(", "),
        "Facts : " + org_unit.facts.map(&:to_s).join(", ")
      ]
    end

    attr_reader :org_unit_id, :pyramid

    def org_unit
      @org_unit ||= begin
            raw_org_unit = pyramid.org_unit(org_unit_id)
            Orbf::RulesEngine::OrgUnitWithFacts.new(
              orgunit: raw_org_unit,
              facts:   Orbf::RulesEngine::OrgunitFacts.new(raw_org_unit, pyramid).to_facts
            )
          end
    end
  end
end