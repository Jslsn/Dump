import json
import boto3
import os
#Assigning boto3 tools
s3= boto3.client('s3')

TargetBucket=os.environ['TargetBucket']
TargetPath=os.environ['TargetPath']
SourceBucket=os.environ['SourceBucket']

def lambda_handler(event, context):
    #Reading the s3 event received to assign certain information to variables
    S3Key=event["Records"][0]["s3"]["object"]['key']
    S3Bucket=event["Records"][0]["s3"]["bucket"]['name']
    print(json.dumps(event))
    if S3Bucket == SourceBucket:
        copy_file(S3Key, S3Bucket)

def copy_file(FileToCopy, SourceBucket):
    print(f'Full source path: s3://{SourceBucket}/{FileToCopy}')
    CopyFilePrefix=FileToCopy.split("/")[0]
    NewFilePath=FileToCopy.replace(CopyFilePrefix, TargetPath)
    print(f'Full target path: s3://{TargetBucket}/{NewFilePath}')
    RunCopy= s3.copy_object(
        CopySource = {
            'Bucket': SourceBucket,
            'Key': FileToCopy
        },
        Bucket = TargetBucket,
        Key = NewFilePath
        )
    print(RunCopy)
    