
class ChangelogEntry
  attr_reader :operation, :path, :human_readable_path, :current_value, :previous_value, :show_detail

  def initialize(hash)
    @operation = hash[:operation]
    @path = hash[:path]
    @human_readable_path = hash[:human_readable_path]
    @current_value = hash[:current_value]
    @previous_value = hash[:previous_value]
    @show_detail = hash[:show_detail]
  end
end
