from slack_sdk import WebhookClient
import boto3
import datetime
import time
import os

#Setting up a few global variables.
WebhookEndpoint=WebhookClient(os.environ['SlackUrl'])
AwsRegion = 'eu-west-2'
Ec2 = boto3.client('ec2')
CloudWatch = boto3.client('cloudwatch')
Account=os.environ['AWSAccount']
RuleName=os.environ['EventRule']
DaysToMonitor=int(os.environ['DaysToMonitor'])
DefinedLowUsage=int(os.environ['DefinedLowUsage'])

#Lambda Handler makes sure it's being reached to from the correct source before passing on to the main function.
def lambda_handler(event, context):
    EventAccount=event['account']
    EventResources=event['resources'][0]
    print (EventAccount)
    print (EventResources)
    if EventAccount == Account and RuleName in EventResources:
        check_instance_usage()

#A weighting function is used to judge whether to alert or not.
def WeightedValueOfList(OldUnweightedList: list):
    NewWeightedList=[]
    #For each value provided in the list of numbers
    for UnweightedValue in OldUnweightedList:
        UnweightedValueCountdown=UnweightedValue
        UnweightedValueRange=[]
        #Create a list out of a given number in the list all the numbers smaller than it.
        while UnweightedValueCountdown != 0:
            UnweightedValueRange.append(UnweightedValueCountdown)
            UnweightedValueCountdown-=1
        #Recreate said list with weighted values by taking each one and squaring them.
        WeightedValueRange=[]
        for GivenValue in UnweightedValueRange:
            WeightedGivenValue=GivenValue*GivenValue
            WeightedValueRange.append(WeightedGivenValue)
        WeightedValue=0
        #Take these new weighted values and add them together to create a new weighted value for the given number in the original list.
        for EachWeightedGivenValue in WeightedValueRange:
            WeightedValue+=EachWeightedGivenValue
        NewWeightedList.append(WeightedValue)
    #Add each weighted value together to create a total value for the list given.
    WeightedTotal=0
    for GivenWeightedValue in NewWeightedList:
        WeightedTotal+=GivenWeightedValue
    return (WeightedTotal)

#Main function does the main processing.
def check_instance_usage():
    #Setting the days to check CloudWatch for.

    #Find the maximum weighted value to compare against from this set number of days.
    MaxDayCounter = 0
    MaxValueList=[]
    while MaxDayCounter < DaysToMonitor:
        MaxValueList.append(MaxDayCounter)
        MaxDayCounter+=1
    MaxValue = WeightedValueOfList(MaxValueList)
    print(MaxValue)

    #Get a list of the account's EC2 instances
    InstanceList = Ec2.describe_instances(
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': [
                    'running',
                ]
            },
        ],
    )

    #For each Instance, grab the ID and query CloudWatch for the instance's metrics.
    for Instance in InstanceList['Reservations']:
        InstanceId = Instance['Instances'][0]['InstanceId']
        
        CpuToday = CloudWatch.get_metric_data(
            MetricDataQueries=[
                {
                    'Id': 'cpu',
                    'MetricStat': {
                        'Metric': {
                            'Namespace': 'AWS/EC2',
                            'MetricName': 'CPUUtilization',
                            'Dimensions': [
                                {
                                    'Name': 'InstanceId',
                                    'Value': InstanceId
                                }
                            ]
                        },
                        'Period': 86400,
                        'Stat': 'Maximum',
                        'Unit': 'Percent'
                    }
                },

            ],
            StartTime=(datetime.datetime.now() - datetime.timedelta(days = DaysToMonitor)),
            #We go up until yesterday since the metrics are obviously shifting on the current day.
            EndTime=(datetime.datetime.now() - datetime.timedelta(days = 1))
        )

        #Get a integer list of the compute usage gathered for a given instance.
        ComputeList = []
        for point in CpuToday['MetricDataResults'][0]['Values']:
            #print(point)
            ComputeList.append(int(point))
        
        #Using this list, check which ones fit our low CPU criteria and if so, add the day value instead of the default zero
        DayCounter = 0
        AlertDays=[]
        for ComputeDay in ComputeList:
            if ComputeDay < DefinedLowUsage:
                AlertDays.append(DayCounter)
            else:
                AlertDays.append(0)
            DayCounter += 1

        #This weighted value has an exponential recency bias due to the way we formed the AlertDays variable.
        WeightedCompute = WeightedValueOfList(AlertDays)

        #If the returned weighted value is more than 40% of the total, send a slack alert.
        if (WeightedCompute/MaxValue)*100 > 40:
            message=WebhookEndpoint.send(text=f"Hey, An instance(InstanceId = {InstanceId}) has been running very low for a while!\nI would reccomend you either resize or stop it.")


    print(datetime.datetime.now())

