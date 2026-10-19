#!/bin/bash
# Wait until the GPU edge temperature is below 55 °C (as in docs/benchmarks/STRIX_HALO.md).
t=/sys/class/drm/card1/device/hwmon/hwmon*/temp1_input
until [ $(cat $t) -lt 55000 ]; do sleep 2; done
echo "GPU $(( $(cat $t) / 1000 )) °C"
