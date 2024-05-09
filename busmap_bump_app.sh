#!/bin/bash

# Define project directories
project_directories=(
    "/Users/rumnguyen/StudioProjects/busmap-android-3/"
    "/Users/rumnguyen/StudioProjects/busmap-android-2/"
    "/Users/rumnguyen/StudioProjects/busmap-android/"
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
# PROJECT_CODE=$(echo -e "BUSMAP_TEST\nBUSMAP_MONTHLY_TICKET\nBUSMAP_RANKING\nMOTEL_MAP\nEMBUS\nEMBUS_DRIVER\nBUSMAP_HN\nBUSMAP_ADS_HUB\nSTUDENT_HUB\nWALLET_STAFF\nSTORE_VOUCHER\nPHENIKAA_CONNECT\nMAAS_CONNECT\nVINBUS\nHANH_TRINH_SO_DN" | fzf --prompt="Select project code: ")

# Prompt the user to select build flavor
selected_flavor=$(echo -e "Dev\nPrd" | fzf --prompt="Select build flavor: ")

# Prompt the user to select clean or not clean build
selected_option=$(echo -e "not clean\nclean" | fzf --prompt="Select build option: ")

# Prompt the user to enter the selected version name
# read -p "Enter selected version name: " selected_version_name

# Check if the user entered a version name
# if [ -z "$selected_version_name" ]; then
#     echo "No version name entered. Exiting."
#     exit 1
# fi

# Prompt the user to enter the description
# read -p "Enter description (optional): " DESCRIPTION

# Echo summary of user input in blue color
echo -e "\033[34m"
echo "Build Flavor: $selected_flavor"
echo "Build Option: $selected_option"
echo "Current Git Branch: $git_branch"
echo -e "\033[0m"

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
        # echo -e "\033[32mBuild successful. Uploading APK...\033[0m"
        
        # Set variables for curl request
        # busMap/build/outputs/bundle/devRelease/busMap-dev-release.aab
        FILE_PATH="busMap/build/outputs/bundle/${selected_flavor}Release/busMap-${selected_flavor}-release.aab"

        # Get the APK file size
        file_size=$(ls -lh "${FILE_PATH}" | awk '{print $5}')

        # Extract the file name from the file path
        file_name=$(basename "${FILE_PATH}")

        echo -e "\033[32mBuild successful: $file_name ($file_size)"

        # complete that for me, that here i want to copy FILE_PATH to the destination folder: /Users/rumnguyen/Desktop/busmap-bump-app, but that file must be append system time in the end to unique
        # Get current timestamp
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

        # Define destination directory
        destination_dir="/Users/rumnguyen/Desktop/busmap-bump-app"

        # Define destination file name with timestamp
        destination_file="${destination_dir}/busMap-${selected_flavor}-release-${timestamp}.aab"

        # Copy file to destination with timestamp
        cp "${FILE_PATH}" "${destination_file}"

        # Check if copy was successful
        if [ $? -eq 0 ]; then
            echo "File copied successfully to: ${destination_file}"
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

