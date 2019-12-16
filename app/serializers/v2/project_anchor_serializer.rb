class V2::ProjectAnchorSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :project

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
  has_many :simulations do |project_anchor|
    project_anchor.invoicing_simulation_jobs
  end
end
