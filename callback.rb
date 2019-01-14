require 'json'
require 'aws-sdk'
require 'net/https'

TOKEN_ENDPOINT = "https://slack.com/api/oauth.access"
DENIED_URL = ENV['DENIED_URL']
REGISTERED_URL = ENV['REGISTERED_URL']

CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']
REDIRECT_URI = ENV['REDIRECT_URI']

DYNAMODB_TABLE_NAME = ENV['DYNAMODB_TABLE_NAME']

def write_db(team_id, params)
    client = Aws::DynamoDB::Client.new
    item = {team_id: team_id, params: params}

    client.put_item(table_name: DYNAMODB_TABLE_NAME, item: item)
end

def send_post(url, params)
    p params
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(params)

    res = https.request(req)
    return res.body
end

def oauth2_callback_handler(event:, context:)
    params = event['queryStringParameters']
    if params == nil
        return { statusCode: 400, body: 'No query parameters' }
    end

    error = params['error']
    code = params['code']

    if error != nil
        if error == "access_denied"
            return {
                statusCode: 303,
                headers: {
                    Location: DENIED_URL
                },
            }
        else
            return { statusCode: 200, body: "unknown error" }
        end
    end

    if code == nil
        return { statusCode: 400, body: "No 'code' parameter" }
    end

    body = send_post(TOKEN_ENDPOINT, {
      code: code,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      redirect_uri: REDIRECT_URI
    })

    begin
        json = JSON.parse(body)
    rescue
        puts "body: #{body}"
        return { statusCode: 500, body: "Internal Error. unabled to parse token endpoint's respose." }
    end

    team_id = json['team_id']
    write_db(team_id, json)

    return {
        statusCode: 303,
        headers: {
            Location: REGISTERED_URL
        }
    }
end
