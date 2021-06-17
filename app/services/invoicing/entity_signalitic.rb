# frozen_string_literal: true

module Invoicing
  class EntitySignalitic
    def initialize(pyramid, org_unit_id, contract_service, period)
      @pyramid = pyramid
      @org_unit_id = org_unit_id
      @org_unit = build_org_unit_with_facts(contract_service, period)
    end

    def call
      [
        org_unit.name,
        "Path : " + parents.map(&:name).join(" > "),
        "Groups : " + groups.map(&:name).join(", "),
        "Facts : " + org_unit.facts.map(&:to_s).join(", ")
      ]
    end

    def to_h
      {
        id:                       org_unit_id,
        name:                     org_unit.name,
        ancestors:                parents.map do |p|
                                    {
                                      id:   p.ext_id,
                                      name: p.name
                                    }
                                  end,
        organisation_unit_groups: groups.map do |g|
                                    {
                                      id:   g.ext_id,
                                      name: g.name
                                    }
                                  end,
        facts:                    org_unit.facts
      }
    end

    attr_reader :org_unit_id, :pyramid, :org_unit

    def parents
      org_unit.parent_ext_ids.map { |parent_id| pyramid.org_unit(parent_id) }.reject(&:nil?)
    end

    def groups
      pyramid.groups(org_unit.group_ext_ids)
    end

    def build_org_unit_with_facts(contract_service, period)
      raw_org_unit = pyramid.org_unit(org_unit_id)
      unless raw_org_unit
        contract = contract_service.for(org_unit_id, period)
        raw_org_unit = contract.org_unit if contract
      end
      Orbf::RulesEngine::OrgUnitWithFacts.new(
        orgunit: raw_org_unit,
        facts:   Orbf::RulesEngine::OrgunitFacts.new(org_unit:raw_org_unit, pyramid: pyramid, contract_service:contract_service, invoicing_period: period).to_facts
      )
    end
  end
end
