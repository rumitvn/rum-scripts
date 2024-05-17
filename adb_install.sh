#!/bin/bash



# Ensure the APK path argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: ./install_apk.sh <path_to_apk>"
    exit 1
fi

APK_PATH="$1"

# Get the list of connected devices
DEVICE_LIST=($(adb devices | awk 'NR>1 {print $1}' | grep -v '^$'))

# Check if any devices are connected
if [ ${#DEVICE_LIST[@]} -eq 0 ]; then
    echo "No devices found."
    exit 1
fi

# Display the devices in a numbered list
echo "Select a device:"
echo "0. All devices"
for i in "${!DEVICE_LIST[@]}"; do
    echo "$((i+1)). ${DEVICE_LIST[$i]}"
done

# Prompt the user for a selection
read -p "Enter the number of the device (or 0 for all devices): " selection

# Validate the selection
if [ "$selection" -lt 0 ] || [ "$selection" -gt ${#DEVICE_LIST[@]} ]; then
    echo "Invalid selection."
    exit 1
fi

# Install the APK on the selected device or all devices
if [ "$selection" -eq 0 ]; then
    for device in "${DEVICE_LIST[@]}"; do
        adb -s $device install "$APK_PATH"
        echo "APK installed on device $device."
    done
else
    DEVICE_ID=${DEVICE_LIST[$((selection-1))]}
    adb -s $DEVICE_ID install "$APK_PATH"
    echo "APK installed on device $DEVICE_ID."
fi

