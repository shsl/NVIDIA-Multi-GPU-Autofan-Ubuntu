#!/bin/bash

export DISPLAY=:0

#DELAY=60            # Pause for cycle disabled
MIN_TEMP=45          # Set Min Temperature Target
MAX_TEMP=68          # Set Max Temperature Target
MIN_FAN_SPEED=50     # Set Min Fan Speed applied below MIN_TEMP
MAX_FAN_SPEED=90     # Set Min Fan Speed applied above  MAX_TEMP
ALLINONESTRING=''    # Change all fan's speed at once

# BEGIN
if [[ $MAX_FAN_SPEED > 100 ]]; then
    MAX_FAN_SPEED=90
fi

CARDS_NUM=`nvidia-smi -L | wc -l`
echo "[$(date +"%d/%m/%y %T")] Found ${CARDS_NUM} GPU(s) : MIN ${MIN_TEMP}°C - ${MAX_TEMP}°C MAX : Delay ${DELAY}s"

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
    #fan
    ALLINONESTRING+=" -a [gpu:$i]/GPUFanControlState=1 -a [fan:$((i*2))]/GPUTargetFanSpeed=$FAN_SPEED -a [fan:$((i*2+1))]/GPUTargetFanSpeed=$FAN_SPEED"
    echo "GPU${i} ${GPU_TEMP}°C -> ${FAN_SPEED}%"
done

nvidia-settings ${ALLINONESTRING}
