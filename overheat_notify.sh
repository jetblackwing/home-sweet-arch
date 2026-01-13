#!/bin/bash

THRESHOLD=75
ALERTED=0   # prevents repeated notifications

get_cpu_temp() {
    TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
    echo $((TEMP_RAW / 1000))
}

while true; do
    CPU_TEMP=$(get_cpu_temp)

    if [ "$CPU_TEMP" -ge "$THRESHOLD" ] && [ "$ALERTED" -eq 0 ]; then
        notify-send \
        --app-name="Thermal Monitor" \
        --urgency=critical \
        "Warning: System Overheating" \
        "CPU temperature has reached ${CPU_TEMP}°C.\n\nTo prevent system instability or hardware damage, reduce system load or shut down the device immediately."

        ALERTED=1
    fi

    # Reset alert once temperature goes back to safe range
    if [ "$CPU_TEMP" -lt "$THRESHOLD" ]; then
        ALERTED=0
    fi

    sleep 60
done
