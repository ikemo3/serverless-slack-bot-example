# serverless-slack-bot-example

[Serverless Framework](https://serverless.com/), [AWS Lambda](https://aws.amazon.com/lambda/), [Ruby](http://www.ruby-lang.org/)を使ったSlackボットの例です。

## 機能

* エンドポイント
    * OAuth 2.0の認可エンドポイントにリダイレクト
    * OAuth 2.0のコールバックエンドポイント
    * イベント購読
* 1アカウントで2ステージ(dev, prod)
* Amazon SNSを使ってイベント購読とリプライを分離
