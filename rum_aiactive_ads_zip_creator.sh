#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
    echo "Usage: $0 <path_to_index.html> <target_directory> [optional:compression_options]"
    exit 1
fi

# Assign mandatory arguments to variables
INDEX_HTML="$1"
TARGET_DIR="$2"

# Assign optional compression options if provided
OPTION_COMPRESS="${3:-}" # If not provided, defaults to an empty string

# Rest of the variables
RESULTS_DIR="results"
ZIP_COUNT=0

# Check if the index.html file and target directory exist
if [ ! -f "$INDEX_HTML" ] || [ ! -d "$TARGET_DIR" ]; then
    echo "Error: index.html file or target directory does not exist."
    exit 1
fi

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Iterate over each .png file in the target directory
for png_file in "$TARGET_DIR"/*.png; do
    # Check if png_file is a file
    if [ -f "$png_file" ]; then
        # Extract filename without extension
        base_name=$(basename "$png_file" .png | tr ' ' '_')

        # Create a temporary directory for the zip contents
        TEMP_DIR="${base_name}_temp"
        mkdir -p "$TEMP_DIR"
        
        # Compress the .png file using the provided options, if any
        convert "$png_file" $OPTION_COMPRESS "$TEMP_DIR/banner.png"
        
        # Copy the index.html file into the temporary directory
        cp "$INDEX_HTML" "$TEMP_DIR/index.html"
        
        # Change to the temporary directory
        pushd "$TEMP_DIR" > /dev/null
        
        # Zip the contents of the temporary directory
        zip -rm "../${RESULTS_DIR}/${base_name}.zip" ./*
        
        # Return to the previous directory
        popd > /dev/null
        
        # Remove the temporary directory
        rm -rf "$TEMP_DIR"
        
        # Increment the zip count
        ZIP_COUNT=$((ZIP_COUNT+1))
        
        echo "Created zip for ${base_name}"
    fi
done

# Log the number of created results
echo "Number of zip files created: $ZIP_COUNT"

