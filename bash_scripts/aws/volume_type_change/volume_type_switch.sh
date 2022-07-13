 #!/bin/bash

while getopts "o:n:" opt; do
	case ${opt} in
	    o)
		    oldtype=${OPTARG}
			;;
		n)
			newtype=${OPTARG}
			;;
		*)
			echo "Please provide both the old volume type through -o and the new one you'd like to mass switch to using -n."
			exit 1
	esac
done

region=$(aws configure get region)

volume_ids=$(aws ec2 describe-volumes --region ${region} --filters Name=volume-type,Values=${oldtype} | jq -c '.Volumes[].VolumeId')
    
for volume in ${volume_ids}
do
	volume=${volume:1:$[${#volume}-2]}
	echo "Attempting to modify ${volume}..."
	aws ec2 modify-volume --region ${region} --volume-type=${newtype} --volume-id ${volume}
done