class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    begin
      uri = URI.parse(value)
      resp = uri.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      resp = false
    end
    record.errors[attribute] << (options[:message] || "is not an url") unless resp == true
  end
end
