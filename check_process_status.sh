#!/in/bash

process=$1
arg=$2
basename=`basename $0`

[ -z "$process" -o -z "$arg" ] && { echo 'arg error'; exit ; }

pid=`ps -ef |grep -w $process|grep -v $basename|awk -v var=$arg '{if ($NF==var)print $2}'`
[ -z "$pid" ] && echo 0 || echo 1

