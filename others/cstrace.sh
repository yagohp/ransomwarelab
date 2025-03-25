#!/bin/bash

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo "Error: ADB not found. Please ensure the Android SDK is installed and configured correctly."
    exit 1
fi

if ! command -v adb shell "which strace" &> /dev/null; then
    echo "Error: strace not found. Please install strace to continue."
    exit 1
fi

# Check if argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <com.app.example>"
    exit 1
fi

app_name="$1"
DEVICE_LOG_PATH="/data/local/tmp/strace.log"

echo "Searching for process: $app_name"
echo "----------------------------------"

# Get the PID of the process
pid=$(adb shell pidof "$app_name")

if [ -z "$pid" ]; then
    # in case pidof doesn't work
    pid=$(adb shell ps -A | grep "$app_name" | awk '{print $2}')
fi

if [ -z "$pid" ]; then
    echo "Error: No running process found for '$app_name'"
    exit 1
fi

# Take the last PID if it found more then one
pid=$(echo "$pid" | tail -n 1)
process_info=$(adb shell ps -A | grep "$pid")

echo "Found process:"
echo "$process_info"
echo "----------------------------------"
echo "Starting strace on PID $pid..."
echo "Output will be saved to $DEVICE_LOG_PATH (device)"

# Create output directory
mkdir -p "./logs/$app_name"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
output_file="./logs/$app_name/strace_${TIMESTAMP}.log"

# Clear any existing log file
adb shell "su -c '> $DEVICE_LOG_PATH'"

# Run strace on the device with root permissions
adb shell "su -c 'strace -p $pid -tt -T -v -o $DEVICE_LOG_PATH'" &
STRACE_PID=$!

# Wait for some time (or interact with the app)
echo "Tracing for 60 seconds..."
sleep 60

# Stop strace by killing the background process
kill $STRACE_PID 2>/dev/null

# Pull the log file
adb pull $DEVICE_LOG_PATH "$output_file"

# Clean up the log file on device
adb shell "su -c 'rm $DEVICE_LOG_PATH'"

echo "Strace log saved to: $output_file"
echo "Device log file removed"