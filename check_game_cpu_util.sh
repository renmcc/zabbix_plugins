#!/in/bash

process=$1
arg=$2
[ -z "$process" -o -z "$arg" ] && { echo 'arg error'; exit ; }

pid=`ps -ef |grep -w $process|grep -v check_game_cpu_util|awk -v var=$arg '{if ($NF==var)print $2}'`
[ -z "$pid" ] && { echo 'process not exits'; exit; }

top -b -n 1 -p $pid|grep -w $process|awk '{print $9}'
