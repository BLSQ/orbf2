# frozen_string_literal: true

# Error message with what dhis2 answered: RestClient only says "409 Conflict",
# the reason is in the response body, eg
#
#   409 Conflict: At least one data element, data set or data element group must be specified (E2001)
class Dhis2ErrorMessage
  MAX_BODY_LENGTH = 500

  def self.call(error)
    new(error).call
  end

  # dhis2 json errors have a message (and an errorCode), other bodies are kept as is, shortened
  def self.body_details(body)
    return if body.blank?

    json = JSON.parse(body)
    message = json.is_a?(Hash) && json["message"]
    return body.to_s.truncate(MAX_BODY_LENGTH) if message.blank?

    json["errorCode"].present? ? "#{message} (#{json['errorCode']})" : message
  rescue JSON::ParserError
    body.to_s.squish.truncate(MAX_BODY_LENGTH)
  end

  def initialize(error)
    @error = error
  end

  def call
    details = response_details
    details ? "#{@error.message}: #{details}" : @error.message
  end

  private

  def response_details
    return unless @error.respond_to?(:response) && @error.response.respond_to?(:body)

    self.class.body_details(@error.response.body)
  end
end
