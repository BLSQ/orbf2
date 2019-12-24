class AddPublishEndDateToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :publish_end_date, :datetime
  end
end
