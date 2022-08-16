#!/bin/bash
rm cluster_list.txt
for item in $( aws redshift describe-clusters | grep ClusterIdentifier )
do
if [ ${item:1:17} != ClusterIdentifier ]
then
        echo ${item:1:( ${#item} - 3 )} >> cluster_list.txt
fi
done

echo "Finding cluster cpu usage"
for cluster in $( cat cluster_list.txt  )
do
echo "-------------------------------------------------------------------------"
echo "The average CPU Utilization for the cluster, ${cluster}, for the past 20 days has been as follows:"
cpu_list=$( aws cloudwatch get-metric-data --metric-data-queries '{"Id": "redshift_cpu_usage", "MetricStat": {"Metric":{"Namespace":"AWS/Redshift","MetricName":"CPUUtilization", "Dimensions":[{ "Name": "ClusterIdentifier", "Value":"'"${cluster}"'"}]}, "Stat":"Average","Period": 86400,"Unit":"Percent"}}' --start-time $( date -v -20d  +'%Y-%m-%dT%T' ) --end-time $( date +'%Y-%m-%dT%T' ) | grep -A 19 Values )
count=0
cpu_dates=$( aws cloudwatch get-metric-data --metric-data-queries '{"Id": "redshift_cpu_usage", "MetricStat": {"Metric":{"Namespace":"AWS/Redshift","MetricName":"CPUUtilization", "Dimensions":[{ "Name": "ClusterIdentifier", "Value":"'"${cluster}"'"}]}, "Stat":"Average","Period": 86400,"Unit":"Percent"}}' --start-time $( date -v -20d  +'%Y-%m-%dT%T' ) --end-time $( date +'%Y-%m-%dT%T' ) | grep -A 19 Timestamps )
for point in ${cpu_list}
do
if [ ${point:0:1} != '"'  ] && [ ${point:0:1} != ']'  ] && [ ${point:0:1} != '['  ] && [ ${point:0:1} != '}'  ] && [ ${point:0:1} != '{'  ]
then
    if [ $(echo ${point} | awk '{split($0,spl,"."); print spl[1]};') -le 40 ]
    then
        echo -e "\033[0;32m${point:0:$[ ${#point} - 1 ]} \033[0;0m"
    elif [ $(echo ${point} | awk '{split($0,spl,"."); print spl[1]};') -gt 40 ] && [ $(echo ${point} | awk '{split($0,spl,"."); print spl[1]};') -lt 60 ]
    then
        echo -e "\033[0;33m${point:0:$[ ${#point} - 1 ]} \033[0;0m"
    elif [ $(echo ${point} | awk '{split($0,spl,"."); print spl[1]};') -ge 60 ]
    then
        echo -e "\033[0;31m${point:0:$[ ${#point} - 1 ]} \033[0;0m"
        counter_count=0
        for date in ${cpu_dates}
        do
        if [ ${date:0:1} != ']'  ] && [ ${date:0:1} != '['  ] && [ ${date:0:1} != '}'  ] && [ ${date:0:1} != '{'  ] && [ ${counter_count} = ${count}  ]
        then
            date=${date:1:$[ ${#date} - 3  ]}
            if [ $date != "Timestamps" ]
            then
                echo -e "\033[0;31m!${cluster} has had an average cpu usage of over 60% on ${date:0:$[ ${#date} - 15  ]}(${point:0:$[ ${#point} - 1  ]}%)! \033[0;0m. do you want to run a more localised check for this day?(yes or y to check or no or n to decline)"
                read responce_to_local_search
                if [ $responce_to_local_search = yes ] || [ $responce_to_local_search = y ] || [ $responce_to_local_search = Yes ] || [ $responce_to_local_search = Y ]
                then
                    echo "Okay, here's the check for ${date:0:$[ ${#date} - 15  ]}, noting that this check shows the maximum usage for each hour instead of the average of each day like the broader checks."
                    echo "-------------------------------------------------------------------------"
                    local_check=$( aws cloudwatch get-metric-data --metric-data-queries '{"Id": "redshift_cpu_usage", "MetricStat": {"Metric":{"Namespace":"AWS/Redshift","MetricName":"CPUUtilization", "Dimensions":[{ "Name": "ClusterIdentifier", "Value":"'"${cluster}"'"}]}, "Stat":"Maximum","Period": 3600,"Unit":"Percent"}}' --start-time ${date:0:10} --end-time ${date:0:8}$[${date:8:2} + 1 ] | grep -A 23 Values )
                    for local_point in ${local_check}
                    do
                    if [ ${local_point:0:1} != '"'  ] && [ ${local_point:0:1} != ']'  ] && [ ${local_point:0:1} != '['  ] && [ ${local_point:0:1} != '}'  ] && [ ${local_point:0:1} != '{'  ] && [ ${local_point:1:1} != 'V'  ]
                    then
                            echo ${local_point:0:$[ ${#local_point} - 1 ]}
                    fi
                    done
                    echo "I'd reccomend also looking at this through the console if the levels are particularly high"
                    echo "Ready to resume broader checks?(press enter to continue)"
                    read resume_broader_search
                    echo "Okay, resuming..."
                    sleep 3
                    echo "-------------------------------------------------------------------------"
                elif [ $responce_to_local_search = no ] || [ $responce_to_local_search = n ] || [ $responce_to_local_search = No ] || [ $responce_to_local_search = N ]
                then
                    echo "Okay, resuming cluster checks..."
                    sleep 3
                else
                    echo "Invalid input, resuming cluster checks..."
                    sleep 3
                fi
            fi
        fi
        counter_count=$[ ${counter_count} + 1 ]
        done
    fi
fi
count=$[ ${count} + 1  ]
done
echo ""
echo "-------------------------------------------------------------------------"
done
rm cluster_list.txt