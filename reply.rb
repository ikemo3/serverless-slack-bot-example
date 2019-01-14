require 'json'
require 'aws-sdk'
require 'net/https'

POST_URL = "https://slack.com/api/chat.postMessage"
DYNAMODB_TABLE_NAME = ENV['DYNAMODB_TABLE_NAME']

def get_access_token(team_id)
    client = Aws::DynamoDB::Client.new
    resp = client.get_item({
        table_name: DYNAMODB_TABLE_NAME,
        key: {
            "team_id" => team_id
        },
    })

    if resp == nil
        puts "ERROR: record not found. team_id:#{team_id}"
        return nil
    end

    item = resp['item']
    params = item['params']
    if params == nil
        puts "ERROR: item['params'] not found. team_id:#{team_id}"
        puts "params: #{params}"
        return nil
    end

    bot = params['bot']
    if bot == nil
        puts "ERROR: item['params']['bot'] not found. team_id:#{team_id}"
        puts "params: #{params}"
        return nil
    end

    return bot['bot_access_token']
end

def post_message(access_token:, channel:, text:)
    params = {token: access_token, channel: channel, text: text }
    send_post(POST_URL, params)
end

def send_post(url, params)
    puts "send_post: #{params}"
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(params)

    res = https.request(req)
    puts res.body
end

def slack_reply_handler(event:, context:)
    p event
    records = event['Records']
    if records == nil
        return { statusCode: 400, body: 'Records not found' }
    end

    if records.size != 1
        return { statusCode: 400, body: 'size of Records is not 1' }
    end

    record = records[0]
    sns = record['Sns']
    if sns == nil
        return { statusCode: 400, body: "record['Sns'] is not found" }
    end

    message = sns['Message']
    if message == nil
        return { statusCode: 400, body: "record['Sns']['Message'] is not found" }
    end

    begin
        params = JSON.parse(message)
    rescue
        return { statusCode: 400, body: "Message is not JSON" }
    end

    puts "params: #{params}"

    params_team_id = params['team_id']
    if params_team_id == nil
        return { statusCode: 400, body: "params['team_id'] not found" }
    end

    params_event = params['event']
    if params_event == nil
        return { statusCode: 400, body: "params['event'] not found" }
    end

    channel = params_event['channel']
    if channel == nil
        return { statusCode: 400, body: "params['event']['channel'] not found" }
    end

    user = params_event['user']
    access_token = get_access_token(params_team_id)

    text = "Hello!"
    post_message(access_token: access_token, channel: channel, text: text)

    { statusCode: 200 }
end
