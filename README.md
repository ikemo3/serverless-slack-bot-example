# serverless-slack-bot-example

Slack bot example by [Serverless Framework](https://serverless.com/), [AWS Lambda](https://aws.amazon.com/lambda/), [Ruby](http://www.ruby-lang.org/).

## Feature

* Endpoints
    * Redirect to OAuth 2.0 Authorize Endpoiint.
    * OAuth 2.0 Callback Endpoint.
    * Event Subscription.
* One account, Two stage(dev, prod).
* Separate reply code from Event Subscription(uses Amazon SNS).
