# frozen_string_literal: true

class V2::ProjectAnchorSerializer < V2::BaseSerializer
  attribute :dhis2_url do |project|
    project&.dhis2_url
  end
  attribute :periods do |project|

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
  attribute :cycle do |project|
    project&.cycle
  end
  attribute :name do |project|
    project&.name
  end

  attribute :code do |project|
    project&.project_anchor&.program&.code
  end

  has_many :inputs, serializer: V2::StateSerializer, record_type: "input"  do |project|
    project&.states
  end

  has_many :sets, serializer: V2::PackageSerializer, record_type: "set"  do |project|
    project&.packages
  end

  has_many :compounds, serializer: V2::PaymentRuleSerializer, record_type: "compound"  do |project|
    project.project_anchor.project&.payment_rules
  end

  has_many :simulations do |project|
    project.project_anchor.invoicing_simulation_jobs
  end
end
