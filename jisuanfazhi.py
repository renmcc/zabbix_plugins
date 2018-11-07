#!/usr/bin/env python
#coding=utf-8

from pyzabbix import ZabbixAPI
import time
import datetime
import sys
import re
from multiprocessing import Pool

class zabbix_api:
    def __init__(self,url,account,passwd):
        self.zapi = ZabbixAPI(url)
        try:
            self.zapi.login(account,passwd)
        except Exception as e:
            print(e);sys.exit()

    # 获取指定组信息
    def get_group_message(self,groupname):
        host_ids = self.zapi.do_request(method='hostgroup.get', params={"selectHosts":1, "filter":{"name":groupname}})['result']
        return host_ids

    # 获取指定主机信息
    def get_host_message(self,hostid):
        host_message = self.zapi.do_request(method='host.get', params={"filter": {"hostid":hostid}})['result']
        return host_message

    # 获取指定组中主机指定监控项信息
    def get_item_message(self,groupid,itemname):
        item_message = self.zapi.do_request(method='item.get', params={"groupids":groupid,"filter": {"key_":itemname}})['result']
        return item_message

    # 获取指定主机监控项数据
    def get_item_data(self, hostsid, itemname):
        item_data = self.zapi.do_request(method='item.get', params={"hostids":hostsid, "filter":{"key_":itemname}})['result']
        return item_data

    # 获取监控项历史数据
    def get_history_data(self, itemid, time_till, from_time):
        history_data = self.zapi.do_request(method='history.get',params={"history": 0, "itemids":itemid, "sortfield": "clock","sortorder": "DESC", "time_from":from_time, "time_till":now_time})['result']
        return history_data

    # 获取主机宏
    def get_hosts_macro(self,hostsid):
        macro = self.zapi.do_request(method='usermacro.get',params={"hostids":hostsid})['result']
        return macro

    # 创建主机宏
    def create_host_macro(self,hostid, macroname, value):
        status = self.zapi.do_request(method='usermacro.create', params={"hostid": hostid, "macro":macroname, "value":value})['result']
        return status

    # 更新主机宏
    def update_host_macro(self,hostmacroid,value):
        status = self.zapi.do_request(method='usermacro.update', params={"hostmacroid":hostmacroid, "value":value})['result']
        return status

#计算浮动阈值
def Calculation(item_data, now_time, old_time):
    history_data = obj.get_history_data(item_data['itemid'], now_time, old_time)
    length = len(history_data)
    if length:
        sum_data = sum([float(data['value']) for data in history_data])
        max_value = sum_data / length * size
        min_value = sum_data / length / size
        data = {"itemid":item_data['itemid'],"key":item_data['key'],"hostid":item_data['hostid'],"max_value":max_value,"min_value":min_value}
        return data

if __name__ == "__main__":
    #需要计算哪个组里的主机
    groupname = "game"
    #需要计算哪些监控项历史数据
    itemnames = ["check_disk_status['wKBps']", "check_disk_status['rKBps']"]
    #统计几天前的数据
    days = 7
    #浮动阈值倍数
    size = 1.2
    #数据列表
    item_datas = []


    obj = zabbix_api('http://localhost','Admin','zabbix')

    # 获取groupid
    group_message = obj.get_group_message(groupname)
    groupid = group_message[0]['groupid']

    #获取组中主机的itemid,hostid,itemname(用于定义宏)
    for item in itemnames:
        item_messages = obj.get_item_message(groupid, item)
        for item_message in item_messages:
            dict = {"hostid":item_message['hostid'],"itemid":item_message['itemid'],"key":item_message['key_']}
            item_datas.append(dict)

    #获取当前时间和指定天数前的时间戳
    now_time = datetime.datetime.now()
    old_time = now_time + datetime.timedelta(days=-days)
    now_time = int(time.mktime(now_time.timetuple()))
    old_time = int(time.mktime(old_time.timetuple()))
    #计算阈值
    result_datas = []
    pool = Pool(processes=4)
    process_list = []
    for item_data in item_datas:
        process = pool.apply_async(Calculation, (item_data, now_time, old_time), callback=result_datas.append)
        process_list.append(process)
    pool.close()
    pool.join()
    item_datas = [data for data in result_datas if data]

    #设置主机宏
    for item_data in item_datas:
        #宏名字取item的所有字母
        macro_max = '{$%s}' % (''.join(re.split(r'[^A-Za-z]', item_data['key'])) + 'max').upper()
        macro_min = '{$%s}' % (''.join(re.split(r'[^A-Za-z]', item_data['key'])) + 'min').upper()
        host_macros = obj.get_hosts_macro(item_data['hostid'])
        #遍历主机下所有宏，有最大阈值就更新值，没有就创建
        for macro in host_macros:
            if macro_max == macro['macro']:
                obj.update_host_macro(macro['hostmacroid'], item_data['max_value'])
                break
        else:
            obj.create_host_macro(item_data['hostid'], macro_max, item_data['max_value'])

        # 遍历主机下所有宏，有最小阈值就更新值，没有就创建
        for macro in host_macros:
            if macro_min == macro['macro']:
                obj.update_host_macro(macro['hostmacroid'], item_data['min_value'])
                break
        else:
            obj.create_host_macro(item_data['hostid'], macro_min, item_data['min_value'])



    #print item_datas
