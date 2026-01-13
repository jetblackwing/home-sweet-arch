#!/bin/bash

# Function to get battery percentage
get_battery_level() {
    # Works for most Linux systems
    cat /sys/class/power_supply/BAT0/capacity
}

# Function to check battery and show Zenity warning
check_battery() {
    BATTERY_LEVEL=$(get_battery_level)

    if [ "$BATTERY_LEVEL" -le 20 ]; then
        zenity --warning \
        --title="You are now running on reserved battery power." \
        --text="Battery level is at ${BATTERY_LEVEL}%. Please connect your charger immediately to avoid shutdown." \
        --width=400 \
        --height=200
    fi
}

# Infinite loop to monitor battery every minute
while true; do
    check_battery
    sleep 200  # check every 200 seconds
done
