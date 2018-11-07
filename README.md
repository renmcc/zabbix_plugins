# zabbix_plugins
描述：
=
```
alldiskrw.sh                  #用于检查挂载点是否只读
allmount.sh                   #用于自动发现
allnetface.sh                 #用于自动发现
allport.sh                    #用于自动发现
chec_disk_status_discovery.py #用于自动发现
check_disk_status.sh          #用于检查磁盘IO
jisuanfazhi.py                #用于计算浮动触发器值
check_game_cpu_util.sh
check_process_cpu.sh
check_raid.sh                 #用于检查raid状态

```
原理：
=
```
check_disk_status.sh #正常的自定义脚本，放在zabbix_agent服务器上
jisuanfazhi.py #脚本放到zabbix_server端每分钟执行一次，通过zabbix_api取出7天的监控数据（不足7天取最大，数据是列表），计算出平均值然后乘除1.2算出最大值和最小值，然后通过zabbix_api把最大值和最小值以宏变量赋值到主机上面，之后用宏变量配置触发器。
```
实例：
=
```
[root@zabbix-server ~]# crontab -l
2 * * * * /usr/sbin/ntpdate time.nist.gov clepsydra.dec.com > /dev/null 2>&1
* * * * * /usr/bin/python /usr/local/zabbix/share/zabbix/externalscripts/jisuanfazhi.py > /dev/null 2>&1

[root@zabbix-server ~]# /usr/bin/python /usr/local/zabbix/share/zabbix/externalscripts/jisuanfazhi.py
[{'itemid': u'24140', 'max_value': 56.126158770806704, 'min_value': 38.97649914639355, 'hostid': u'10123', 'key': u'script.check_disk_status[rKBps]'}]

web端配置触发器：
硬盘写操作浮动20
{base_check:script.check_disk_status[wKBps].last(#3,60)}>{$SCRIPTCHECKDISKSTATUSWKBPSMAX} or {base_check:script.check_disk_status[wKBps].last(#3,60)}<{$SCRIPTCHECKDISKSTATUSWKBPSMIN}
```

