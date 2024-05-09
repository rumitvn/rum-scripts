#!/bin/bash

# Check if the local config folder argument is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: ./push_files.sh <local_config_folder> [device_id]"
    exit 1
fi

LOCAL_CONFIG_FOLDER="$1"

# If device_id is provided, use it. Otherwise, pick the first device from adb devices result.
if [ "$#" -eq 2 ]; then
    DEVICE_ID="$2"
else
    DEVICE_ID=$(adb devices | awk 'NR==2 {print $1}')
    if [ -z "$DEVICE_ID" ]; then
        echo "No device found."
        exit 1
    fi
fi

TARGET_FOLDER="/sdcard/PhenikaaMaaS/"

# Check if the target folder exists on the device. If not, create it.
adb -s $DEVICE_ID shell "[ ! -d $TARGET_FOLDER ] && mkdir -p $TARGET_FOLDER"

# Check if the files already exist in the target folder
if adb -s $DEVICE_ID shell "ls $TARGET_FOLDER" | grep -q 'boxes_config.json\|boxes_info.json'; then
    read -p "Files already exist in the target directory. Do you want to overwrite? (y/n) " -n 1 -r
    echo    # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled by user."
        exit 1
    fi
fi

# Push the files to the specified location on the Android device
adb -s $DEVICE_ID push "$LOCAL_CONFIG_FOLDER/boxes_config.json" $TARGET_FOLDER
adb -s $DEVICE_ID push "$LOCAL_CONFIG_FOLDER/boxes_info.json" $TARGET_FOLDER

echo "Files from $LOCAL_CONFIG_FOLDER pushed to $TARGET_FOLDER on device $DEVICE_ID."

