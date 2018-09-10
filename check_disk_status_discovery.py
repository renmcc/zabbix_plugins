#!/usr/bin/env python
#coding=utf-8

import commands
import sys
import re
import json


#if len(sys.argv) < 3:
#    sys.exit()

disk_list = [{"{#RKBPS}":"rKBps"},{"{#WKBPS}":"wKBps"}]
disk_dict = {}

cmd = "iostat -dxk 1 1|grep -w sda |awk '{print $6}'"

return_code, output = commands.getstatusoutput(cmd)

#disk_list.append()
disk_dict["data"] = disk_list
ret = json.dumps(disk_dict)


print(ret)
