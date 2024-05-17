#!/bin/bash

# Define project directories
project_directories=(
    "/Users/rumnguyen/StudioProjects/busmap-android-3/"
    "/Users/rumnguyen/StudioProjects/busmap-android-2/"
    "/Users/rumnguyen/StudioProjects/busmap-android/"
    "/Users/rumnguyen/StudioProjects/vinbus-app-android-temp/"
)

# Loop through each directory and prompt the user to select
selected_directory=$(for directory in "${project_directories[@]}"; do
    # Log the Git branch name of the current directory
    git_branch=$(cd "$directory" && git rev-parse --abbrev-ref HEAD)
    echo "$directory - Git branch: $git_branch"
done | fzf --prompt="Select project directory: " | cut -d' ' -f1)

# Change directory to the selected project directory
cd "$selected_directory"

# Log the Git branch name of the selected directory
git_branch=$(git rev-parse --abbrev-ref HEAD)
echo "Git branch of selected directory: $git_branch"

# Prompt the user to select project code
PROJECT_CODE=$(echo -e "BUSMAP_TEST\nBUSMAP_MONTHLY_TICKET\nBUSMAP_RANKING\nMOTEL_MAP\nEMBUS\nEMBUS_DRIVER\nBUSMAP_HN\nBUSMAP_ADS_HUB\nSTUDENT_HUB\nWALLET_STAFF\nSTORE_VOUCHER\nPHENIKAA_CONNECT\nMAAS_CONNECT\nVINBUS\nHANH_TRINH_SO_DN" | fzf --prompt="Select project code: ")

selected_bunlde_id=$(echo -e "com.t7.busmap\ncom.t7.busmap.staging\nvn.vinbus.app\nvn.vinbus.app.prd" | fzf --prompt="Select bundle/app ID: ")

# Prompt the user to select build flavor
selected_flavor=$(echo -e "Dev\nPrd" | fzf --prompt="Select build flavor: ")

# Prompt the user to select clean or not clean build
selected_option=$(echo -e "not clean\nclean" | fzf --prompt="Select build option: ")

# Prompt the user to enter the selected version name
read -p "Enter selected version name: " selected_version_name

# Check if the user entered a version name
if [ -z "$selected_version_name" ]; then
    echo "No version name entered. Exiting."
    exit 1
fi

# Prompt the user to enter the description
read -p "Enter description (optional): " DESCRIPTION

# Echo summary of user input in blue color
echo -e "\033[34m"
echo "Project Code: $PROJECT_CODE"
echo "Build Flavor: $selected_flavor"
echo "Build Option: $selected_option"
echo "Selected Version Name: $selected_version_name"
echo "Description: $DESCRIPTION"
echo "Current Git Branch: $git_branch"
echo -e "\033[0m"

# Check if the user selected an option
if [ -n "$selected_option" ] && [ -n "$selected_flavor" ]; then
    # Execute the selected option
    case "$selected_option" in
        "clean")
            build_command="./gradlew clean assemble${selected_flavor}Release"
            ;;
        "not clean")
            build_command="./gradlew assemble${selected_flavor}Release"
            ;;
    esac

    # Check if gradlew script exists
    if [ ! -f "./gradlew" ]; then
        echo "Error: gradlew script not found in selected directory."
        exit 1
    fi

    # Check if gradlew has executable permission
    if [ ! -x "./gradlew" ]; then
        echo "Changing permissions for gradlew..."
        chmod +x ./gradlew
        chmod_result=$?
        echo "chmod result: $chmod_result"
    fi


    # Run the selected build command
    $build_command

    # Check if the build was successful
    if [ $? -eq 0 ]; then
        # Green color for success message
        # echo -e "\033[32mBuild successful. Uploading APK...\033[0m"
        
        # Set variables for curl request
        DEVICE_ID="mobile-cli"
	    AUTH_TOKEN="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MzA1NTMsImZpcnN0TmFtZSI6IlJ1bSIsImxhc3ROYW1lIjoiTmd1eeG7hW4iLCJpYXQiOjE2MTQ1ODAwMDYsImV4cCI6NDc3MDM0MDAwNn0.ZoO2gIDdJHoIFGyIOv3b-2xizBAyjNiKlbpVprcMNXw"
        TITLE="$selected_version_name $selected_flavor"
        VERSION="$selected_version_name"
        
        FILE_PATH="busMap/build/outputs/apk/${selected_flavor}/release/busMap-${selected_flavor}-universal-release.apk"

        # Get the APK file size
        file_size=$(ls -lh "busMap/build/outputs/apk/${selected_flavor}/release/busMap-${selected_flavor}-universal-release.apk" | awk '{print $5}')

        # Extract the file name from the file path
        file_name=$(basename "busMap/build/outputs/apk/${selected_flavor}/release/busMap-${selected_flavor}-universal-release.apk")

        echo -e "\033[32mBuild successful: $file_name ($file_size)"

        echo -e "Uploading APK...\033[0m"
        
        # Upload APK using curl
        response=$(curl --write-out "%{http_code}" --silent --output /dev/null --location 'http://20.191.156.90/admin/system/upload_app_test' \
        --header "device-id: $DEVICE_ID" \
        --header "Authorization: $AUTH_TOKEN" \
        --form "projectCode=\"$PROJECT_CODE\"" \
        --form "title=\"$TITLE\"" \
        --form "description=\"$DESCRIPTION\"" \
        --form "version=\"$VERSION\"" \
        --form "bundleId=\"$selected_bunlde_id\"" \
        --form "file=@\"$FILE_PATH\"")
        
        # Check if upload was successful
        if [ "$response" -eq 200 ]; then
            # Green color for success message
            echo -e "\033[32mUpload successful.\033[0m"
        else
            # Red color for failure message
            echo -e "\033[31mUpload failed.\033[0m"
            echo "Upload response: $response"
        fi

    else
        # Red color for failure message
        echo -e "\033[31mBuild failed.\033[0m"
    fi
else
    # No option selected, exiting
    echo "No option selected. Exiting."
    exit 1
fi

