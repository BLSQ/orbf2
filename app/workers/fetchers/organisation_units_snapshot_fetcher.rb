# frozen_string_literal: true

module Fetchers
  class OrganisationUnitsSnapshotFetcher
    def initialize(fields:)
      @fetcher = GenericSnapshotFetcher.new(fields: fields)
    end

    def fetch_data(project, kind, params)
      raise "OrganisationUnitsSnapshotFetcher works only on organisation_units" unless kind == :organisation_units

      filters = build_filters(project)
      filters.each_with_object([]) do |filter, data|
        data.push(*fetcher.fetch_data(project, kind, { filter: filter }.merge(params)))
      end
    end

    private

    attr_reader :fetcher

    def build_filters(project)
      paths = fetch_paths_for_contracted_entities(project)

      region_paths = paths.map { |path| path.split("/")[0..2].join("/") }.uniq
      country_paths = region_paths.map { |path| path.split("/")[0..1].join("/") }.uniq

      filters = region_paths.map { |region_id| "path:like:#{region_id}" }
      filters += country_paths.map { |country_id| "path:eq:#{country_id}" }

      filters
    end

    def fetch_paths_for_contracted_entities(project)
      path_holder = project.dhis2_connection
                           .organisation_unit_groups
                           .list(
                             filter: "id:eq:" + project.entity_group.external_reference,
                             fields: "organisationUnits[path]"
                           )
                           .first
      path_holder.organisation_units.map { |ou| ou["path"] }
    end
  end
end
