#!/bin/bash

while true; do
    # Check for adb devices
    devices=$(adb devices | grep -v "List of devices attached" | grep "device$")
    
    # If devices found, break the loop
    if [ ! -z "$devices" ]; then
        echo "Device connected!"
        break
    else
        echo "Waiting for device..."
        sleep 5  # waits for 5 seconds before checking again
    fi
done
