#!/bin/bash

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo "Error: ADB not found. Please ensure the Android SDK is installed and configured correctly."
    exit 1
fi

# Check if arguments are provided
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <com.app.example1> <com.app.example2> ..."
    exit 1
fi

echo "Searching for processes matching: $@"
echo "----------------------------------"

for arg in "$@"; do
    echo ">>> Processes containing '$arg':"
    
    # Extract PIDs and details using awk (more reliable than grep)
    adb shell ps -A | grep "$arg" | awk '{print $2 "\t" $9}' | while read -r pid name; do
        echo "PID: $pid   Name: $name"
    done
    
    echo "----------------------------------"
done