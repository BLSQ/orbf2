class ChangeBlankToNilToActivityState < ActiveRecord::Migration[5.0]
  def up
    ActivityState.where(external_reference: '', kind: 'formula').update_all(external_reference: nil)
  end
end
