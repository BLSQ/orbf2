class Program < ApplicationRecord
  has_one :project, inverse_of: :program, dependent: :destroy
end
