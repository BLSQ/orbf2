class ActivityPackage < ApplicationRecord
  belongs_to :package
  belongs_to :state
end
