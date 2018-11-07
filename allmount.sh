#!/bin/bash

port_array=(`df|grep '^/'|awk '{print $NF}'|sort |uniq 2>/dev/null`)

length=${#port_array[@]}

printf "{\n"

printf '\t'"\"data\":["

for ((i=0;i<$length;i++))

do

printf '\n\t\t{'

printf "\"{#MOUNT_POINT}\":\"${port_array[$i]}\"}"

if [ $i -lt $[$length-1] ];then

printf ','

fi

done

printf "\n\t]\n"

printf "}\n"
