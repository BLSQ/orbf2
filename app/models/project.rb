class Project < ApplicationRecord

  validates :dhis2_url, url: true
  validates :name, presence: true

  validates :user, presence: true
  validates :password, presence: true

end
