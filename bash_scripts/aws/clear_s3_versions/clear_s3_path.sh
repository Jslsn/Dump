 #!/bin/bash
  
item=$true
   
while getopts "b:p:" opt; do
	case ${opt} in
	     b)
		    bucket=${OPTARG}
			;;
		p)
			path=${OPTARG}
			;;
		*)
			echo "Please provide both a bucket using -b and a path/key in the bucket using -p."
		    exit 1
	esac
done
				        
if [ $OPTIND -eq 1 ]
then
	echo "No options were passed, please use both -b and -p to define the bucket and bucket path respectively."
	     exit 1
fi
	   
echo "Collecting a list of versions from the ${path} path in the ${bucket} bucket..."

regular_version_list=$(aws s3api list-object-versions --bucket ${bucket} --prefix ${path} --query "Versions[].{Key: Key, Ver: version_id}")
delete_marker_list=$(aws s3api list-object-versions --bucket ${bucket} --prefix ${path} --query "DeleteMarkers[].{Key: Key, Ver: version_id}")

default_IFS=$IFS
	  
IFS=$'\n'

for item in $( echo "${regular_version_list}" | jq -c '.[]' )
do
object_key=$(echo ${item} |  jq ."Key")
object_key=${object_key:1:$[${#object_key}-2]}
version_id=$(echo ${item} |  jq ."Ver")
version_id=${version_id:1:$[${#version_id}-2]}
echo "Deleting ${object_key}, version id: ${version_id}"
aws s3api delete-object --bucket ${bucket} --key ${object_key} --version-id ${version_id}
done

for item in $( echo "${delete_marker_list}" | jq -c '.[]' )
do
   	object_key=$(echo ${item} |  jq ."Key")
	object_key=${object_key:1:$[${#object_key}-2]}
	version_id=$(echo ${item} |  jq ."Ver")
	version_id=${version_id:1:$[${#version_id}-2]}
	echo "Deleting ${object_key}, version id: ${version_id}"
	aws s3api delete-object --bucket ${bucket} --key ${object_key} --version-id ${version_id}
done

IFS=$default_IFS