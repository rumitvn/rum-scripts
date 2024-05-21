#!/bin/bash

CONFIG_DIR="$HOME/.config/rum-scripts"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Check if .config directory and config.json file exist
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: $CONFIG_DIR directory does not exist. Exiting."
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE does not exist. Exiting."
    exit 1
fi

# Read configuration from JSON config file
upload_token=$(jq -r '.upload_token' "$CONFIG_FILE")
project_directories=$(jq -r '.project_directories[]' "$CONFIG_FILE")
project_codes=$(jq -r '.project_codes[]' "$CONFIG_FILE")
bundle_ids=$(jq -r '.bundle_ids[]' "$CONFIG_FILE")
flavors=$(jq -r '.flavors[]' "$CONFIG_FILE")
upload_url=$(jq -r '.upload_url' "$CONFIG_FILE")
device_id=$(jq -r '.device_id' "$CONFIG_FILE")

if [ -z "$upload_token" ]; then
    echo "Error: upload_token not found in config file. Exiting."
    exit 1
fi

# Loop through each directory and prompt the user to select
selected_directory=$(for directory in $project_directories; do
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
PROJECT_CODE=$(echo "$project_codes" | tr ' ' '\n' | fzf --prompt="Select project code: ")

# Prompt the user to select bundle/app ID
selected_bundle_id=$(echo "$bundle_ids" | tr ' ' '\n' | fzf --prompt="Select bundle/app ID: ")

# Prompt the user to select build flavor
selected_flavor=$(echo "$flavors" | tr ' ' '\n' | fzf --prompt="Select build flavor: ")

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
echo "Version Name: $selected_version_name"
echo "Version Description: $DESCRIPTION"
echo "Git Branch: $git_branch"
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
        TITLE="$selected_version_name $selected_flavor"
        VERSION="$selected_version_name"

        FILE_PATH="busMap/build/outputs/apk/${selected_flavor}/release/busMap-${selected_flavor}-universal-release.apk"

        # Get the APK file size
        file_size=$(ls -lh "$FILE_PATH" | awk '{print $5}')

        # Extract the file name from the file path
        file_name=$(basename "$FILE_PATH")

        echo -e "\033[32mBuild successful: $file_name ($file_size)"

        echo -e "Uploading APK...\033[0m"

        # Upload APK using curl
        response=$(curl --write-out "%{http_code}" --silent --output /dev/null --location "$upload_url" \
        --header "device-id: $device_id" \
        --header "Authorization: $upload_token" \
        --form "projectCode=\"$PROJECT_CODE\"" \
        --form "title=\"$TITLE\"" \
        --form "description=\"$DESCRIPTION\"" \
        --form "version=\"$VERSION\"" \
        --form "bundleId=\"$selected_bundle_id\"" \
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
