#!/bin/bash

### BEGIN INIT INFO
# Name:             Autofan script for NVIDIA Cards in HiveOS
# Preparation:      Setting up script sheduled run from CRON (Crontab)
#                    1) Copy script to /home/user/script/ (create folder script).
#                    2) Run mc -> go to script folder
#                    3) Make script executable - execute command in the same folder - chmod u+x autofan.sh.
# Sheduled-Start:    4) Edit crontab (sudo crontab -E) and add line */5 * * * * /home/user/script/autofan.sh
#                       This command will start script every 5 minutes, if you want to change - correct "*/5" value.
#                    5) Edit hive/etc/crontab.root to have autofan running from Cron after reboot.
# Additional Info:  DELAY is not applicable unless the script is set-up for single running in cycles
### END INIT INFO

#sleep 30
export DISPLAY=:0

#DELAY=60            # Pause for cycle disabled / пауза для цикла замкнутого цикла while-do - отключена для однократного запуска
MIN_TEMP=45          # Set Min Temperature Target / порог минимальной температуры
MAX_TEMP=68          # Set Max Temperature Target / порог максимальной температуры
MIN_FAN_SPEED=50     # Set Min Fan Speed applied below MIN_TEMP / Минимальная скорость вентиляторов, применяется при температуре ниже MIN_TEMP
MAX_FAN_SPEED=90     # Set Min Fan Speed applied above  MAX_TEMP / Максимальная скорость вентиляторов, применяется при температуре выше MAX_TEMP
ALLINONESTRING=''    # Change all speed at once   
# BEGIN

if [[ $MAX_FAN_SPEED > 100 ]]; then
    MAX_FAN_SPEED=100
fi

n=`gpu-detect NVIDIA`
if [ $n == 0 ]; then
    echo "[$(date +"%d/%m/%y %T")] No NVIDIA cards detected, exiting"
    exit
fi

CARDS_NUM=`nvidia-smi -L | wc -l`
echo "[$(date +"%d/%m/%y %T")] Found ${CARDS_NUM} GPU(s) : MIN ${MIN_TEMP}°C - ${MAX_TEMP}°C MAX : Delay ${DELAY}s"
echo "[$(date +"%d/%m/%y %T")] Found ${CARDS_NUM} GPU(s) : MIN ${MIN_TEMP}°C - ${MAX_TEMP}°C MAX"
#while true # this while-do-done cycle is disabled for single-run from cron, to be setup in cron
#do         # цикл while-do отключен для однократного запуска скрипта из cron
#echo "$(date +"%d/%m/%y %T")"
#echo "$(date +"%d/%m/%y %T")"

for ((i=0; i<$CARDS_NUM; i++))
do
GPU_TEMP=`nvidia-smi -i $i --query-gpu=temperature.gpu --format=csv,noheader`
if [[ $GPU_TEMP < $MIN_TEMP ]]
then
FAN_SPEED=$MIN_FAN_SPEED
elif [[ $GPU_TEMP > $MAX_TEMP ]]
then
FAN_SPEED=$MAX_FAN_SPEED
else
FAN_DIFF=$(($MAX_FAN_SPEED-$MIN_FAN_SPEED))
FAN_SPEED_ADDED=$(( ($GPU_TEMP - $MIN_TEMP)*$FAN_DIFF/($MAX_TEMP - $MIN_TEMP) ))
FAN_SPEED=$(($MIN_FAN_SPEED+$FAN_SPEED_ADDED))
fi
result=`nvidia-settings -a [gpu:$i]/GPUFanControlState=1 | grep "assigned value 1"`
test -z "$result" && echo "GPU${i} ${GPU_TEMP}°C -> Fan speed management is not supported" && exit 1
#nvidia-settings -a [gpu:$i]/GPUFanControlState=1 | grep -v "^$" > /dev/null
ALLINONESTRING+=" -a [fan:$i]/GPUTargetFanSpeed=$FAN_SPEED -a [fan:$i+1]/GPUTargetFanSpeed=$FAN_SPEED"
i++
echo "GPU${i} ${GPU_TEMP}°C -> ${FAN_SPEED}%"
echo "GPU${i} ${GPU_TEMP}°C -> ${FAN_SPEED}%"
done

nvidia-settings ${ALLINONESTRING} > /dev/null

#sleep $DELAY
#done
