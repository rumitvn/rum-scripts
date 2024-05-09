#!/bin/bash

# Check for saver mode
MODE_OPTIONS=""
if [ "$1" == "saver" ]; then
    MODE_OPTIONS="-m 1024 -b 2M --max-fps=30"
fi

# Get the list of connected devices
DEVICE_LIST=($(adb devices | awk 'NR>1 {print $1}' | grep -v '^$'))

# Check if any devices are connected
if [ ${#DEVICE_LIST[@]} -eq 0 ]; then
    echo "No devices found."
    exit 1
fi

# Display the devices in a numbered list
echo "Select a device to cast:"
for i in "${!DEVICE_LIST[@]}"; do
    echo "$((i+1)). ${DEVICE_LIST[$i]}"
done

# Prompt the user for a selection
read -p "Enter the number of the device: " selection

# Validate the selection
if [ "$selection" -lt 1 ] || [ "$selection" -gt ${#DEVICE_LIST[@]} ]; then
    echo "Invalid selection."
    exit 1
fi

# Get the selected device ID
DEVICE_ID=${DEVICE_LIST[$((selection-1))]}

# Start scrcpy with the selected device and mode options
scrcpy -s $DEVICE_ID $MODE_OPTIONS

