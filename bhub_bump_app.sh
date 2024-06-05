#!/bin/zsh

# Define a function to get the IP address for a given box name
get_ip_for_box() {
    case "$1" in
        "GI1") echo "192.168.12.43" ;;
        "GI2") echo "192.168.12.44" ;;
        "GI3") echo "192.168.12.42" ;;
        "GI4") echo "192.168.12.32" ;;
        "GI5") echo "192.168.12.40" ;;
        "GO1") echo "192.168.12.35" ;;
        "GO2") echo "192.168.12.39" ;;
        "BV1") echo "192.168.12.41" ;;
        "BV2") echo "192.168.12.23" ;;
        "DP1") echo "192.168.12.28" ;;
        "DP2") echo "192.168.12.45" ;;
        "DNAI_CONG_VU") echo "a.bsmart.city:5008" ;;
        *) echo "" ;;
    esac
}

# Define the package name of the service
service_package="com.bsmart.scanner.service.SmartPortService"

# Define an array of box names
boxes=("GI1" "GI2" "GI3" "GI4" "GI5" "GO1" "GO2" "BV1" "BV2" "DP1" "DP2" "DNAI_CONG_VU")

# Prompt user to select a box
box_name=$(printf "%s\n" "${boxes[@]}" | fzf --prompt="Select a box: ")

# Define the directory containing the APK files
apk_directory="/Users/rumnguyen/Desktop/bhub-bump-app"

# Get a list of APK files in the directory
apk_files=($apk_directory/*.apk)

# Prompt user to select an APK file
apk_file=$(printf "%s\n" "${apk_files[@]}" | fzf --prompt="Select an APK file: ")

echo -e "\033[34m"
echo "Box name: $box_name"
echo "APK file path: $apk_file"
echo -e "\033[0m"

if [[ -n $box_name && -n $apk_file ]]; then
    ip=$(get_ip_for_box "$box_name")

    # Connect to the device using adb
    adb -s $ip connect $ip > /dev/null 2>&1

    # Check if the connection was successful
    if [ $? -eq 0 ]; then
        # Connection successful, get storage information
        storage_info=$(adb -s $ip shell df | grep '/data')

        # Extract available, used, and usage percentage
        available_bytes=$(echo "$storage_info" | awk '{print $4}')
        used_bytes=$(echo "$storage_info" | awk '{print $3}')
        use_percent=$(echo "$storage_info" | awk '{print $5}')

        # Convert bytes to megabytes
        available_mb=$(echo "scale=2; $available_bytes / 1024" | bc)
        used_mb=$(echo "scale=2; $used_bytes / 1024" | bc)

        echo "Box $box_name ($ip): Available: ${available_mb}MB, Used: ${used_mb}MB, Use%: $use_percent"

        # Push the APK to the device
        # if adb -s $ip push "$apk_file" /sdcard/PhenikaaMaaS/ > /dev/null 2>&1; then
        #     echo -e "\033[32mSuccessfully pushed $apk_file to $box_name ($ip)\033[0m"
        # else
        #     echo -e "\033[31mFailed to push $apk_file to $box_name ($ip)\033[0m" >&2
        # fi
        adb -s $ip push "$apk_file" /sdcard/PhenikaaMaaS/

        # Disconnect from the device
        adb disconnect $ip > /dev/null 2>&1
    else
        # Connection failed
        echo -e "\033[31mBox $box_name ($ip): Offline\033[0m"
    fi
else
    echo -e "\033[31mNo box or APK file selected.\033[0m"
fi
