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
project_directories=$(jq -r '.project_directories[]' "$CONFIG_FILE")
flavors=$(jq -r '.flavors[]' "$CONFIG_FILE")
browser_app=$(jq -r '.browser_app' "$CONFIG_FILE")
destination_dir=$(jq -r '.destination_dir' "$CONFIG_FILE")
google_play_console_url=$(jq -r '.google_play_console_url' "$CONFIG_FILE")

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

# Prompt the user to select build flavor
selected_flavor=$(echo "$flavors" | tr ' ' '\n' | fzf --prompt="Select build flavor: ")

# Prompt the user to select clean or not clean build
selected_option=$(echo -e "not clean\nclean" | fzf --prompt="Select build option: ")

# Echo summary of user input in blue color
echo -e "\033[34m"
echo "Build Flavor: $selected_flavor"
echo "Build Option: $selected_option"
echo "Current Git Branch: $git_branch"
echo "Google Play Console URL: $google_play_console_url"
echo -e "\033[0m"

git pull

# Check if the user selected an option
if [ -n "$selected_option" ] && [ -n "$selected_flavor" ]; then
    # Execute the selected option
    case "$selected_option" in
        "clean")
            build_command="./gradlew clean bundle${selected_flavor}Release"
            ;;
        "not clean")
            build_command="./gradlew bundle${selected_flavor}Release"
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
        FILE_PATH="busMap/build/outputs/bundle/${selected_flavor}Release/busMap-${selected_flavor}-release.aab"

        # Get the APK file size
        file_size=$(ls -lh "${FILE_PATH}" | awk '{print $5}')

        # Extract the file name from the file path
        file_name=$(basename "${FILE_PATH}")

        echo -e "\033[32mBuild successful: $file_name ($file_size)\033[0m"

        # Get current timestamp
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

        # Define destination file name with timestamp
        destination_file="${destination_dir}/busMap-${selected_flavor}-release-${timestamp}.aab"

        # Copy file to destination with timestamp
        cp "${FILE_PATH}" "${destination_file}"

        # Check if copy was successful
        if [ $? -eq 0 ]; then
            echo "File copied successfully to: ${destination_file}"
            open ${destination_dir}

            # Open Google Play Console URL in Chrome
            open -a "$browser_app" "$google_play_console_url"
        else
            echo "Error copying file."
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
