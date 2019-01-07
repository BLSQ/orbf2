# frozen_string_literal: true

class DhisDemoResolver
  # The play.dhis2.org/demo now redirects to the latest stable release
  # of dhis2, this class tries to figure out what the exact url is.
  #
  # Usage:
  #
  #      DhisDemoResolver.new.call
  #      #= Returns the url to latest stable release as a string
  class TooManyRedirects < StandardError; end

  def initialize(url = "https://play.dhis2.org/demo", limit = 10)
    @url = url
    @limit = limit
  end

  def call(location = @url)
    res = Net::HTTP.get_response(URI(location))
    case res
    when Net::HTTPSuccess then
      res["location"]
    when Net::HTTPRedirection then
      new_location = res["location"]
      if new_location.end_with?("action")
        # We've gone too far and are being redirected to the login page.
        location
      else
        @limit -= 1
        raise TooManyRedirects if @limit < 1

        call(new_location)
      end
    else
      res.value
    end
  end
end
