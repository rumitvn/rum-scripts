#!/bin/bash

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

# Function to pull data from a device to a destination directory
pull_data_from_device() {
    local DEVICE_ID="$1"
    local DEST_DIR="$2"
    # Create the destination directory if it does not exist
    mkdir -p "$DEST_DIR"
    # Pull the directory
    adb -s "$DEVICE_ID" pull "sdcard/PhenikaaMaaS" "$DEST_DIR"
    echo "Pulled sdcard/PhenikaaMaaS from device $DEVICE_ID to $DEST_DIR."
}

# Handle the pull operation
if [ "$selection" -eq 0 ]; then
    # For all devices
    for i in "${!DEVICE_LIST[@]}"; do
        # Get default directory name for each device
        if [ -z "$1" ]; then
            DEST_DIR="$((i+1))-${DEVICE_LIST[$i]}"
        else
            DEST_DIR="$1/${DEVICE_LIST[$i]}"
        fi
        pull_data_from_device "${DEVICE_LIST[$i]}" "$DEST_DIR"
    done
else
    # For the selected device
    DEVICE_ID=${DEVICE_LIST[$((selection-1))]}
    # Get the destination directory or set to default if not provided
    if [ -z "$1" ]; then
        DEST_DIR="${selection}-${DEVICE_ID}"
    else
        DEST_DIR="$1"
    fi
    pull_data_from_device "$DEVICE_ID" "$DEST_DIR"
fi

