CLIENT_ID = ENV['CLIENT_ID']
SCOPE = ENV['SCOPE']
REDIRECT_URI = ENV['REDIRECT_URI']
AUTHORIZE_URL = "https://slack.com/oauth/authorize?client_id=#{CLIENT_ID}&scope=#{SCOPE}&rediret_uri=#{REDIRECT_URI}"

def authorize(event:, context:)
    return {
        statusCode: 302,
        headers: {
            Location: AUTHORIZE_URL
        },
    }
end
