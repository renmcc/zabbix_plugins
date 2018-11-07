#!/bin/bash
OK=0
Waring=1
Critical=2
Unknown=3
Error=0
MegaRAID="/opt/MegaRAID/MegaCli/MegaCli*"
Tmpdir="/tmp/zabbixtmp"

################Delete temporary directory
function Cleartmpdir() {
    [ -d ${Tmpdir} ] && rm -rf ${Tmpdir}
}
################Generate raw data
function Generate_Source_File() {
    mkdir -p ${Tmpdir} && chown -R zabbix.zabbix ${Tmpdir}
    if [ -f ${MegaRAID} ]; then 
        sudo ${MegaRAID} -LDInfo -Lall -aALL > ${Tmpdir}/raidlevel
        sudo ${MegaRAID} -AdpBbuCmd -aAll > ${Tmpdir}/batteryinfo
        sudo ${MegaRAID} -PDList -aAll > ${Tmpdir}/diskinfo
        sudo ${MegaRAID} -LDGetProp -Cache -L0 -a0 > ${Tmpdir}/cacheinfo
        sudo ${MegaRAID} -cfgdsply -aALL > ${Tmpdir}/baseinfo
    else
        { echo -n "Unknown:No checkraid tools!"; Cleartmpdir; exit ${Critical}; }
    fi
    if [ `cat ${Tmpdir}/raidlevel|wc -l` -le 7 ]; then
        { echo -n "Unknown:No hardware raid!"; Cleartmpdir; exit ${Unknown}; }
    fi
    Raid_Count=`cat ${Tmpdir}/raidlevel|grep '(Target Id:'|awk '{print $NF}'|awk -F ')' '{print $1}'`
    Remaining_Capacity=`cat ${Tmpdir}/batteryinfo|grep "^Remaining Capacity"|awk 'NR==1{print $1$2$3$4}'`
    Product_Name=`cat ${Tmpdir}/baseinfo|awk 'NR==4{print $1$2$3$4$5}'`
}
###############check raid status 
function CheckRaid_Status() {
    local I
    for I in ${Raid_Count}; do
        local Raid_State=`cat ${Tmpdir}/raidlevel|sed -n "/(Target Id: ${I})/,/State/"p|awk -F ': ' '/State/{print $2}'`
        [ -z ${Raid_State} ] && { echo -n "Critical:CheckRaid_Status function error"; Cleartmpdir; exit ${Critical}; }
        if [ "${Raid_State}" != "Optimal" ] ;then
            echo -n "VirtualDrive${I}StateError:${Raid_State} "
            Error=$[${Error}+2]
        fi
    done
}
##############check disk of raid BadSector loose onlie
function CheckRaid_DiskStatus() {
    local I  
    local SlotNumber=`cat ${Tmpdir}/diskinfo|awk '/^Slot Number/{print $3}'`
    for I in ${SlotNumber}; do
        local Media_Errorount=`cat ${Tmpdir}/diskinfo|sed -n "/Slot Number: ${I}/,/Other Error Count/"p|awk '/^Media Error Count/{print $NF}'`
        local Other_Errorount=`cat ${Tmpdir}/diskinfo|sed -n "/Slot Number: ${I}/,/Other Error Count/"p|awk '/^Other Error Count/{print $NF}'`
        local Firmware_State=`cat ${Tmpdir}/diskinfo|sed -n "/Slot Number: ${I}/,/Firmware state/"p|awk '/^Firmware state/{print $NF}'`
        [ -z ${Media_Errorount} ] || [ -z ${Other_Errorount} ] || [ -z ${Firmware_State} ] && { echo -n "Critical:CheckRaid_DiskStatus function error"; Cleartmpdir; exit ${Critical} ; } 
        if [ "${Media_Errorount}" -ge "100" ]; then
            echo -n "SlotNumber${I}:BadSectors:${Media_Errorount} " 
            Error=$[${Error}+2]
        elif [ "${Other_Errorount}" -ne "0" ]; then
            echo -n "SlotNumber${I}:DiskLooseNeedToRePlug " 
            Error=$[${Error}+2]
        elif [ "${Firmware_State}" != "Up" -a "${Firmware_State}" != "Online" ]; then
            echo -n "SlotNumber${I}:NotOnline " 
            Error=$[${Error}+2]
        fi
    done
}
################check raid charger
function CheckRaid_Charger() {
    local Charger_Status=`cat ${Tmpdir}/batteryinfo|grep "Charger Status"|awk '{print $3}'`
    local Relative_State_of_Charge=`cat ${Tmpdir}/batteryinfo|grep "^Relative State of Charge"|awk 'NR==1{print $5}' `
    [ -z ${Charger_Status} ] || [ -z ${Relative_State_of_Charge} ] && { echo -n "Critical:CheckRaid_Charger function error"; Cleartmpdir; exit ${Critical} ; }
    if [ "${Charger_Status}" != "Complete" ]; then
        echo -n "BatteryInCharge "
        Error=$[${Error}+1]
    elif [ $Relative_State_of_Charge -lt 40 ]; then
        echo -n "Charge:$Relative_State_of_Charge% "
        Error=$[${Error}+2]
    fi
}
##############normal output
function Normal_Output() {
    local I count disk
    local Raid_Mem=`cat ${Tmpdir}/baseinfo|awk 'NR==5{print $1$2}'`
    local Relative_State_of_Charge=`cat ${Tmpdir}/batteryinfo|grep "^Relative State of Charge"|awk 'NR==1{print $4$5$6}'`
    local Cache_Status=`cat ${Tmpdir}/cacheinfo| awk -F[/:/,] 'NR==2{print $4}'`
    echo -n "${Product_Name} ${Raid_Mem} CacheStatus:${Cache_Status} ${Relative_State_of_Charge} ${Remaining_Capacity} "
    for I in ${Raid_Count}; do
        local NumberOfDrives=`cat ${Tmpdir}/raidlevel|sed -n "/(Target Id: ${I})/,/Number Of Drives/"p|awk -F ':' '/Number Of Drives/{print $2}'`
        local SpanDepth=`cat ${Tmpdir}/raidlevel|sed -n "/(Target Id: ${I})/,/Span Depth/"p|awk -F ':' '/Span Depth/{print $2}'`
        local DiskCount_Raid=$[${NumberOfDrives}*${SpanDepth}]
        local Raid_Name=`cat ${Tmpdir}/raidlevel|sed -n "/(Target Id: ${I})/,/Name/"p|awk -F ':' 'NR==2{print $2}'|awk '{print $1$2}'`
        local Raid_Level=`cat ${Tmpdir}/raidlevel|sed -n "/(Target Id: ${I})/,/RAID Level/"p|awk -F':' 'NR==3{print $2}'|awk '{print $1$2}'`
        local Raid_Size=`cat ${Tmpdir}/raidlevel|sed -n "/(Target Id: ${I})/,/^Size/"p|awk -F ':' 'NR==4{print $2}'|awk '{print $1$2}'`
        echo -n "[RaidName:${Raid_Name} RaidLevel:${Raid_Level} ${Raid_Size} "
        for count in ${DiskCount_Raid}; do
            echo -n "diskcount:${count}] "
        done
    done
}
##############Main
function Main() {
    Generate_Source_File
    CheckRaid_Status 
    CheckRaid_DiskStatus
    if [ "${Product_Name}" != "ProductName:PERCH310Mini" ]; then
        CheckRaid_Charger
    fi
}
Main

case ${Error} in
    0) 
        echo -n "OK: "
        Normal_Output
        Cleartmpdir
        exit ${OK} ;;
    1)
        echo -n "Waring"
        Cleartmpdir
        exit ${Waring};;
    *) 
        echo -n "Critical"
        Cleartmpdir
        exit ${Critical};;
esac
