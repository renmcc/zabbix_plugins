#!/bin/bash

if [ $# -ne 1 ];then
    echo "Follow the script name with an argument"
fi

case $1 in 

    rrqm)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $2}'`
        echo $info
        ;;

    wrqm)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $3}'`
        echo $info
        ;;

    rps)
        info=`iostat -dxk 1 1|grep -w sda|awk '{print $4}'`
        echo $info
        ;;

    wps)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $5}'`
        echo $info
        ;;

    rKBps)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $6}'`
        echo $info
        ;;

    wKBps)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $7}'`
        echo $info
        ;;

    avgrq-sz)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $8}'`
        echo $info
        ;;

    avgqu-sz)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $9}'`
        echo $info
        ;;

    await)
        info=`iostat -dxk 1 1|grep -w sda|awk '{print $10}'`
        echo $info
        ;;

    svctm)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $13}'`
        echo $info
        ;;

    util)
        info=`iostat -dxk 1 1|grep -w sda |awk '{print $14}'`
        echo $info
        ;;

    *)
        echo -e "\e[033mUsage: sh $0 [rrqm|wrqm|rps|wps|rKBps|wKBps|avgqu-sz|avgrq-sz|await|svctm|util]\e[0m"
esac
