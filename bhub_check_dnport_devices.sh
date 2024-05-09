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

if [[ -n $box_name ]]; then
    ip=$(get_ip_for_box "$box_name")

    # Connect to the device using adb
    adb -s $ip connect $ip > /dev/null 2>&1

    # Check if the connection was successful
    if [ $? -eq 0 ]; then
        # Connection successful, check the status of the service
        service_status=$(adb -s $ip shell dumpsys activity services | grep $service_package)

        # Check if the service is running
        if [ -n "$service_status" ]; then
            echo "Box $box_name ($ip): SmartPortService is running"
        else
            echo "Box $box_name ($ip): SmartPortService is not running"
        fi
    else
        # Connection failed
        echo "Box $box_name ($ip): Offline"
    fi

    # Disconnect from the device
    adb disconnect $ip > /dev/null 2>&1
else
    echo "No box selected."
fi

