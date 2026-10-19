#!/bin/bash
# Every 0.5 s: time, package power (PPT, W), GPU clock (MHz), edge temperature (°C), GPU busy (%), as TSV.
h=$(echo /sys/class/drm/card1/device/hwmon/hwmon*)
while true; do
  printf '%s\t%s\t%s\t%s\t%s\n' "$(date +%s.%N)" "$(( $(cat $h/power1_input) / 1000000 ))" \
    "$(( $(cat $h/freq1_input) / 1000000 ))" "$(( $(cat $h/temp1_input) / 1000 ))" \
    "$(cat /sys/class/drm/card1/device/gpu_busy_percent)"
  sleep 0.5
done
