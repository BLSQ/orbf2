# frozen_string_literal: true

class V2::ProjectAnchorSerializer < V2::BaseSerializer
  attribute :dhis2_url do |project_anchor|
    project_anchor.project&.dhis2_url
  end
  attribute :periods do |project_anchor|
    project = project_anchor.project
    if project
      start_year = 2016
      end_year = project.calendar.from_iso(DateTime.now).year + 1
      (start_year..end_year).flat_map {|year| project.calendar.periods(year.to_s,"quarterly")}
    else
      []
    end
  end
  attribute :created_at
  attribute :updated_at
  attribute :cycle do |project_anchor|
    project_anchor.project&.cycle
  end
  attribute :name do |project_anchor|
    project_anchor.project&.name
  end

  attribute :code do |project_anchor|
    project_anchor.program&.code
  end

  has_many :inputs do |project_anchor|
    project_anchor.project&.states
  end

  has_many :simulations do |project_anchor|
    project_anchor.invoicing_simulation_jobs
  end
end
