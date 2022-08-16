#!/bin/bash

while getopts "n:" opt; 
do  
    case ${opt} in
        n)
            number=${OPTARG}  
            range=()  
            while [ ${number} != 0 ]
            do
                range=(${range[@]} ${number})
                number=$[${number}-1]
            done
            total=0
            for given_number in ${range[@]}
            do
                total=$[${total}+$[${given_number}*${given_number}]]
            done
            echo ${total}
            ;;
        *)
            echo "Please give a number after using the -n flag"
    esac
done


