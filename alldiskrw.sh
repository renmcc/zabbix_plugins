#!/bin/bash
mountpoint=$1
for i in ${mountpoint}; do
    mount|awk '$3 ~ /^\'${i}'$/'|awk '{print $NF}'|cut -c 2-3|awk '{if($1~/ro/) {print 1}}'|wc -l|awk '{if($1<=0) {print 0 } else {print 1}}'
done
