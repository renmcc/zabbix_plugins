#!/bin/bash

netface_array=(`ifconfig|grep -o "^[^[:space:]]\{1,\}"|awk -F: '{print $1}'|grep -v '^lo$'|sort |uniq 2>/dev/null`)

length=${#netface_array[@]}

printf "{\n"

printf '\t'"\"data\":["

for ((i=0;i<$length;i++))

do

printf '\n\t\t{'

printf "\"{#NET_FACE}\":\"${netface_array[$i]}\"}"

if [ $i -lt $[$length-1] ];then

printf ','

fi

done

printf "\n\t]\n"

printf "}\n"
