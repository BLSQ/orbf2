
class ChangelogEntry
  include ActiveModel::Model
  attr_accessor :operation, :path, :human_readable_path, :current_value, :previous_value, :show_detail
end
