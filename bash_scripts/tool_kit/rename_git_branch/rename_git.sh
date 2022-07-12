#!/bin/bash

while getopts "o:n:" opt; do
	case ${opt} in
	    o)
		    oldbranch=${OPTARG}
			;;
		n)
			newbranch=${OPTARG}
			;;
		*)
			echo "Please provide both the old branch through -o and the new one you'd like to rename your branch to using -n."
		    exit 1
	esac
done

git branch -m $oldbranch $newbranch
git push origin -u $newbranch
git push origin --delete $oldbranch
