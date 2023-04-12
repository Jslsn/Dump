# Basic S3 Copy Serverless Function

This is a basic serverless function created through AWS SAM that copies files from one directory to another(Due to the way SAM works, the source bucket has to be created in the template).

This template path will create a basic Lambda Function using AWS SAM. The Lambda will trigger on every file upload to a given bucket path and copy the uploaded file to another path. One **IMPORTANT NOTE** is that due to the way SAM builds these functions the source bucket must be one created through the template, the target can be one that already exists or the same created bucket.

## Deployment

### Prerequisites

- Slack Webhook is created

- Install AWS SAM CLI - https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html 

### Deploying:
   - Make a copy of the sample_samconfig.toml called samconfig.toml and fill it with the correct information <"Fill in anything within  marks like this">.
      - The S3 bucket for storing templates can be anything(though I don't reccomend it be the buckets involved in this copying whatsoever), if you already have a default bucket for this kind of thing, best to use that.
   - Run "sam build -t S3_Copy.yml"
   - Run "sam deploy"

   
