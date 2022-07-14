#!/bin/bash
rm cluster_list.txt
rm 10_days
for item in $( aws redshift describe-clusters | grep ClusterIdentifier )
do
if [ ${item:1:17} != ClusterIdentifier ]
then
        echo ${item:1:( ${#item} - 3 )} >> cluster_list.txt
fi
done

echo "Finding cluster disk usage"

for cluster in $( cat cluster_list.txt  )
do
echo "-------------------------------------------------------------------------"
echo "The disk space used for the cluster, ${cluster}, is currently:"
current_disk_usage=$( aws cloudwatch get-metric-data --metric-data-queries '{"Id": "redshift_disk_usage", "MetricStat": {"Metric":{"Namespace":"AWS/Redshift","MetricName":"PercentageDiskSpaceUsed", "Dimensions":[{ "Name": "ClusterIdentifier", "Value":"'"${cluster}"'"}]}, "Stat":"Maximum","Period": 60,"Unit":"Percent"}}' --start-time $( date -v -2H  +'%Y-%m-%dT%T' ) --end-time $( date +'%Y-%m-%dT%T' ) | awk '/"Values":/{getline;print}' )
current_disk_usage=${current_disk_usage:0:$[ ${#current_disk_usage} - 1  ]}
current_disk_usage="${current_disk_usage}%"
echo ${current_disk_usage}
echo ""
aws cloudwatch get-metric-data --metric-data-queries '{"Id": "redshift_disk_usage", "MetricStat": {"Metric":{"Namespace":"AWS/Redshift","MetricName":"PercentageDiskSpaceUsed", "Dimensions":[{ "Name": "ClusterIdentifier", "Value":"'"${cluster}"'"}]}, "Stat":"Maximum","Period": 60}}' --start-time $( date -v -1M -v -10d  +'%Y-%m-%dT%T' ) --end-time $( date -v -10d  +'%Y-%m-%dT%T' ) | awk '/"Values":/{getline;print}' > 10_days
ten_days=$( cat 10_days )
ten_days_check=${ten_days:15:2}
if [ $ten_days_check = "at" ]
then
    echo "This cluster most likely did not exist 10 days ago."
else
    echo "Compared to this 10 days ago:"
    past_disk_usage=$(cat 10_days)
    past_disk_usage="${past_disk_usage}% "
    echo ${past_disk_usage}

fi
echo "-------------------------------------------------------------------------"
done
rm 10_days
rm cluster_list.txt