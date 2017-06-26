module PaperTrailed
  extend ActiveSupport::Concern

  included do
    has_paper_trail meta: { project_id: :project_id, program_id: :program_id }
  end
end
