module Agents
  class TwitterPublishv2Agent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule 'every_1h'

    description do
      <<-MD
      The Twitter Publishv2 Agent publishes tweets from the events it receives.

      #{twitter_dependencies_missing if dependencies_missing?}

      To be able to use this Agent you need to authenticate with Twitter with [twurl](https://github.com/twitter/twurl).

      You must also specify a `message` parameter, you can use [Liquid](https://github.com/huginn/huginn/wiki/Formatting-Events-using-Liquid) to format the message.
      Additional parameters can be passed via `parameters`.

      `debug` is used for verbose mode.

      `consumer_key` is mandatory for oauth.

      `consumer_secret` is mandatory for oauth.

      `access_token` is mandatory for oauth.

      `token_secret` is mandatory for oauth.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "data": {
              "edit_history_tweet_ids": [
                "XXXXXXXXXXXXXXXXXXX"
              ],
              "id": "XXXXXXXXXXXXXXXXXXX",
              "text": "test huginn agentv2 part3 with created event"
            }
          }
    MD

    def default_options
      {
        'message' => "{{text}}",
        'debug' => 'false',
        'consumer_key' => '',
        'consumer_secret' => '',
        'access_token' => '',
        'token_secret' => '',
        'emit_events' => 'true',
        'expected_receive_period_in_days' => '2',
      }
    end

    form_configurable :message, type: :string
    form_configurable :consumer_key, type: :string
    form_configurable :consumer_secret, type: :string
    form_configurable :access_token, type: :string
    form_configurable :token_secret, type: :string
    form_configurable :debug, type: :boolean
    form_configurable :emit_events, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string
    def validate_options
      unless options['consumer_key'].present?
        errors.add(:base, "consumer_key is a required field")
      end

      unless options['consumer_secret'].present?
        errors.add(:base, "consumer_secret must be true or false")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      unless options['access_token'].present?
        errors.add(:base, "access_token must be true or false")
      end

      unless options['token_secret'].present?
        errors.add(:base, "token_secret must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          publish()
        end
      end
    end

    def check
      publish()
    end

    private

    def log_curl_output(code,body)

      log "request status : #{code}"

      if interpolated['debug'] == 'true'
        log "body"
        log body
      end

    end

    def publish()

      url = URI.parse('https://api.twitter.com/2/tweets')
      data = { 'text' => interpolated['message'] }
      json_data = data.to_json
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(url.path,
        { 'Content-Type' => 'application/json' })
      
      consumer = OAuth::Consumer.new(interpolated['consumer_key'], interpolated['consumer_secret'])
      token = OAuth::AccessToken.new(consumer, interpolated['access_token'], interpolated['token_secret'])
      
      request.oauth! http, consumer, token
      request.body = json_data
      response = http.request(request)
      
      log_curl_output(response.code,response.body)

      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end
    end

  end
end
