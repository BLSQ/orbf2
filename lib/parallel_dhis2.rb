# frozen_string_literal: true

class ParallelDhis2
  # A class that takes a regular `Dhis2::Client` and allows us to use
  # parallel requests to send data values. It does this by using the
  # `typhoeus` gem, which handles all the parallelization without us
  # having to worry about it.
  #
  # client = Dhis2::Client.new(url:                 "https://play.dhis2.org/2.34.1",
  #                            user:                "admin",
  #                            password:            "district",
  #                            no_ssl_verification: false,
  #                            debug:               true
  #                           )
  #      parallel_dhis2 = ParallelDhis2.new(client)
  #      parallel_dhis2.post_data_value_sets(array_of_data_values)
  #
  # This class tries to borrow as much configuration from the regular
  # DHIS2 client as possible, it also tries to mimick the behavior of
  # the regular client.
  #
  # This means that the response gotten from `post_data_value_sets`
  # will be a `Dhis2::Status` as well, the only difference will be
  # that the `Dhis2::Status#raw_status` will contain a rolled up
  # version of the parallel requests being made.
  #
  # If HTTP errors are encountered, similar to the normal client,
  # exceptions will be raised, these are not the same ones that the
  # `Dhis2::Client` is raising (they would raise `RestClient`
  # exceptions, while here we're using our own namespace).
  class HttpError < StandardError; end
  class TimedOut < HttpError; end
  class HttpException < HttpError; end
  class InvalidJSON < HttpError; end

  # Amount of items to include in a single request
  SEND_VALUES_PER = 1000
  # Max amount of concurrent request, others will be queued until
  # queue has room again
  MAX_CONCURRENT_REQUESTS = 20

  class RollUpResponses
    ERROR = "ERROR"
    WARNING = "WARNING"
    SUCCESS = "SUCCESS"

    # Takes an array of Dhis2-responses and rolls them up into one
    # Dhis2-response which has the same layout as each of the
    # individual ones. It will have the status of the worst one. So
    # Error > Warning > Success.
    def initialize(responses)
      @responses = responses
    end

    def call
      return {} if @responses.empty?

      response = {
        "status"            => status,
        "description"       => description,
        "import_count"      => import_count,
        "response_type"     => response_type,
        "import_options"    => import_options,
        "data_set_complete" => data_set_complete
      }
      response.merge!("conflicts" => conflicts) if conflicts.any?
      response
    end

    def rolled_up
      @rolled_up ||= @responses.each_with_object({}) do |response, result|
        response.each do |key, value|
          result[key] ||= []
          result[key] << value
        end
      end
    end

    def status
      return ERROR if rolled_up["status"].include? ERROR
      return WARNING if rolled_up["status"].include? WARNING
      return SUCCESS if rolled_up["status"].include? SUCCESS

      ERROR
    end

    def conflicts
      (rolled_up["conflicts"] || []).flatten
    end

    def description
      rolled_up["description"].uniq.join(" && ") + " [parallel]"
    end

    def import_count
      # "{\"deleted\": 0, \"ignored\": 3, \"updated\": 411, \"imported\": 0}"
      rolled_up["import_count"].each_with_object({}) do |hash, result|
        hash.each do |key, value|
          result[key] ||= 0
          result[key] += value
        end
      end
    end

    def response_type
      # Always ImportSummary
      rolled_up["response_type"].uniq.first
    end

    def import_options
      rolled_up["import_options"].flatten
    end

    def data_set_complete
      # Practically always false
      (rolled_up["data_set_complete"] || []).compact.uniq.first
    end
  end

  class ClientWrapper
    # Wraps a regular Dhis2::Client in a loving embrace so we can get
    # access to `base_url`, `verify_ssl` and others.
    #
    # The tests are setup to break if a nicer interface than directly
    # getting the instance variables is set up.
    def initialize(dhis2_client)
      @client = dhis2_client
    end

    def user
      CGI.unescape(base_uri.user)
    end

    def password
      CGI.unescape(base_uri.password)
    end

    def url
      uri = base_uri.dup
      uri.user = nil
      uri.password = nil
      uri.to_s
    end

    def base_uri
      @base_uri ||= URI.parse(base_url)
    end

    # Returns a fully authenticated url to the DHIS2-instance
    def base_url
      @client.instance_variable_get(:@base_url)
    end

    def debug?
      @client.instance_variable_get(:@debug)
    end

    # Returns one of these:
    #  OpenSSL::SSL::VERIFY_NONE
    #  OpenSSL::SSL::VERIFY_PEER
    def verify_ssl_settings
      @client.instance_variable_get(:@verify_ssl)
    end

    def ssl_verify_peer?
      verify_ssl_settings == OpenSSL::SSL::VERIFY_PEER
    end

    def time_out_settings
      @client.instance_variable_get(:@timeout)
    end

    # Most likely it will return:
    #       {Accept: "json", Content-Type: "application/json"}
    def post_headers
      headers = @client.send(:headers, "post", {})
      headers.delete(:params)
      headers["Accept"] = "application/#{headers.delete(:accept).to_s}"
      headers["Content-Type"] = "application/#{headers.delete(:content_type)}"
      headers
    end
  end

  # dhis2_client - An instance of `Dhis2::Client`
  def initialize(dhis2_client)
    @client = ClientWrapper.new(dhis2_client)
  end

  def prepare_payload(payload)
    Dhis2::Case.deep_change(payload, :camelize).to_json
  end

  # Mostly here as a sanity check if the client starts misbehaving,
  # will issue a single request and return the response, which will
  # have `body` and `code` and `return_code`, which helps debugging.
  def get(url = "/api/system/info")
    url = File.join(@client.url, url)
    request = Typhoeus::Request.new(url,
                                    method:         :get,
                                    headers:        @client.post_headers,
                                    ssl_verifypeer: @client.ssl_verify_peer?,
                                    userpwd:        [@client.user, @client.password].join(":"))
    request.run
    request.response
  end

  def build_post_request(url, payload)
    body = prepare_payload(payload)
    Typhoeus::Request.new(url,
                          method:         :post,
                          headers:        @client.post_headers,
                          body:           body,
                          timeout:        @client.time_out_settings,
                          ssl_verifypeer: @client.ssl_verify_peer?,
                          userpwd:        [@client.user, @client.password].join(":"))
  end

  def post_data_value_sets(all_values)
    hydra = Typhoeus::Hydra.new(max_concurrency: MAX_CONCURRENT_REQUESTS)
    requests = []
    url = File.join(@client.url, "api", "dataValueSets")
    all_values.each_slice(SEND_VALUES_PER).with_index do |values, i|
      request = build_post_request(url, dataValues: values)
      if @client.debug?
        request.on_complete do |response|
          # rubocop:disable Style/FormatStringToken
          #
          # I like that I can use the %02d part, right in the
          # formatting string, that's why I've disabled rubocop here.
          message = format("[parallel_dhis2] %s [%02d] completed. (%s took %s)",
                           url,
                           i + 1,
                           response.code,
                           response.total_time)
          # rubocop:enable Style/FormatStringToken
          puts message
        end
      end

      hydra.queue(request)
      requests << request
    end
    # This blocks until all requests are done.
    hydra.run

    responses = requests.map(&:response)
    parsed_responses = parse_responses(responses)
    raw_status = RollUpResponses.new(parsed_responses).call
    Dhis2::Status.new(raw_status)
  end

  def parse_responses(responses)
    check_for_errors!(responses)

    parsed = responses.map do |response|
      next if [nil, ""].include?(response.body)

      parsed_response = JSON.parse(response.body)
      Dhis2::Case.deep_change(parsed_response, :underscore)
    end
    parsed.compact
  rescue JSON::ParserError => e
    raise InvalidJSON, e
  end

  def check_for_errors!(responses)
    responses.each do |response|
      next if response.success?

      if response.timed_out?
        message = "#{response.effective_url} timed out"
        raise TimedOut, message
      else
        message = "#{response.effective_url} returned #{response.code}: #{response.return_message}"
        raise HttpException, message
      end
    end
  end
end
