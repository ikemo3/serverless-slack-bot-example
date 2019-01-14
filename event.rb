require 'json'
require 'aws-sdk'
require 'openssl'

TOPIC_ARN = ENV['TOPIC_ARN']
SIGNING_SECRET = ENV['SIGNING_SECRET']

def publish(params)
    sns = Aws::SNS::Client.new
    sns.publish({
        topic_arn: TOPIC_ARN,
        message: JSON.generate(params),
    })
end

def slack_event_handler(event:, context:)
    puts "event: #{event}"

    headers = event['headers']
    timestamp = headers['X-Slack-Request-Timestamp'] rescue nil
    if timestamp == nil || timestamp.empty?
        puts "'X-Slack-Request-Timestamp' not found"
        return { statusCode: 400, body: "'X-Slack-Request-Timestamp' not found" }
    end

    signature_header = headers['X-Slack-Signature'] rescue nil
    if signature_header == nil || signature_header.empty?
        puts "'X-Slack-Signature' not found"
        return { statusCode: 400, body: "'X-Slack-Signature' not found" }
    end

    # timestamp within 5 min.
    if (Time.now.to_i - timestamp.to_i).abs > 300
        puts "The request timestamp is more than 5min."
        return { statusCode: 400, body: "The request timestamp is more than 5min." }
    end

    body = event['body']
    if body == nil || body == ""
        puts "Body not found."
        return { statusCode: 400, body: "Body not found." }
    end

    puts "body: #{body}"

    signature_base = 'v0:' + timestamp + ':' + body
    digest = OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, SIGNING_SECRET, signature_base)

    if "v0=" + digest != signature_header
        puts "'X-Slack-Signature' not match."
        return { statusCode: 403, body: "'X-Slack-Signature' not match" }
    end

    begin
        params = JSON.parse(body)
    rescue
        puts "Body is not JSON"
        return { statusCode: 400, body: 'Body is not JSON' }
    end

    type = params['type']
    if type == "url_verification"
        challenge = params['challenge']
        return { statusCode: 200, body: challenge }
    end

    if type != "event_callback"
        puts "param #{type} is not supported"
        return { statusCode: 400, body: "param #{type} is not supported" }
    end

    event = params['event']
    if event == nil
        puts "params['event'] is not found"
        return { statusCode: 400, body: "params['event'] is not found" }
    end

    event_type = event['type']
    if event_type != "app_mention"
        puts "event param #{type} is not supported"
        return { statusCode: 400, body: "event param #{type} is not supported" }
    end

    publish(params)

    return { statusCode: 200 }
end
