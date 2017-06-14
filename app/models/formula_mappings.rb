class FormulaMappings
  include ActiveModel::Model
  attr_accessor :mappings, :project, :mode
  has_paper_trail
end
