# frozen_string_literal: true

class V2::ProjectAnchorSerializer < V2::BaseSerializer
  attribute :dhis2_url do |project_anchor|
    project_anchor.project&.dhis2_url
  end
  attribute :periods do |_project_anchor|
    %w[2016Q1 2016Q2 2016Q3 2016Q4
       2017Q1 2017Q2 2017Q3 2017Q4
       2018Q1 2018Q2 2018Q3 2018Q4
       2019Q1 2019Q2 2019Q3 2019Q4]
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
