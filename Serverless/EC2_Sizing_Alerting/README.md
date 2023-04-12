# Monitor EC2 usage function 

This is a serverless function created through AWS SAM that monitors the usage on ec2 instances within a given account and gives you smart(ish) alerting on if action is needed for cost efficiency. This could be useful in certain cases, I promise.

This template path will create a Lambda Function using AWS SAM. This function will trigger regularly(intervals are set in parameters) and notify the appropriate/set slack channel when an ec2 has been running on average too close to or too far bellow their limits to be cost efficient.

## Deployment

### Prerequisites

- Slack Webhook is made in the appropriate slack workspace/organisation. 

- Install AWS SAM CLI - https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-mac.html

### Deploying:
   - Set up an "Incoming Webhook" slack app/bot, setting it to point at the channel you want to be informed.
   - Make a copy of the sample_samconfig.toml called samconfig.toml and fill it with the correct information <"Fill in anything within  marks like this">.
      - The S3 bucket for storing templates can be anything. If you already have a default bucket for this kind of thing in the correct region, best to use that.
   - Run "sam build -t ec2-usage-check.yml"
   - Run "sam deploy"

