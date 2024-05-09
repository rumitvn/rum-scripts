#!/bin/zsh

# Define an array of region codes
region_codes=("hcm" "hn")

# Prompt user to select a region code
region_code=$(printf "%s\n" "${region_codes[@]}" | fzf --prompt="Select a region code: ")

if [[ -n $region_code ]]; then
  API_URL="https://api.busmap.vn/v2/public/compress_data_by_time?regionCode=$region_code"
  DEVICE_ID_HEADER="device-id: rum-macos"

  # Define an array of download paths
  download_paths=("/Users/rumnguyen/XcodeProjects/busmap-ios-2/BusMap/BusMap" "/Users/rumnguyen/XcodeProjects/busmap-ios/BusMap/BusMap" "/Users/rumnguyen/StudioProjects/busmap-android/busMap/src/main/res/raw" "/Users/rumnguyen/StudioProjects/busmap-android-2/busMap/src/main/res/raw" )

  # Prompt user to select a download path
  download_folder=$(printf "%s\n" "${download_paths[@]}" | fzf --prompt="Select a download folder: ")

  if [[ -n $download_folder ]]; then
    NEW_FILE_NAME="${region_code}_data.zip"
    NEW_FILE_PATH="$download_folder/$NEW_FILE_NAME"

    if [[ -f "$NEW_FILE_PATH" ]]; then
      EXISTING_FILE_CHECKSUM=$(md5 -q "$NEW_FILE_PATH")
    else
      EXISTING_FILE_CHECKSUM=""
    fi

    curl -s -H "$DEVICE_ID_HEADER" "$API_URL" | jq -r '.url' | xargs curl -o "$NEW_FILE_PATH" -L

    NEW_FILE_CHECKSUM=$(md5 -q "$NEW_FILE_PATH")

    if [[ "$EXISTING_FILE_CHECKSUM" == "$NEW_FILE_CHECKSUM" ]]; then
      echo -e "\033[32mBusData region $region_code is already latest\033[0m"
    else
      echo -e "\033[34mBusData region $region_code is updated\033[0m"
    fi

    # Log the current Git branch
    cd "$download_folder" || exit
    git_branch=$(git rev-parse --abbrev-ref HEAD)
    echo -e "\033[36mCurrent Git branch: $git_branch\033[0m"
  else
    echo -e "\033[31mNo download folder selected.\033[0m"
  fi
else
  echo -e "\033[31mNo region code selected.\033[0m"
fi
