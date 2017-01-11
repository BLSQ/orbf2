class Program < ApplicationRecord
  has_one :project, inverse_of: :program, dependent: :destroy
  has_many :users

  def invalid_project?
    project.nil? || project.invalid?
  end
end
