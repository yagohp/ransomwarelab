#!/bin/bash

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo "Error: ADB not found. Please ensure the Android SDK is installed and configured correctly."
    exit 1
fi

# Check for required tools on device
if ! adb shell "command -v strace" &> /dev/null; then
    echo "Error: strace not found on device. Please install strace to continue."
    exit 1
fi

if ! adb shell "/data/local/tmp/tcpdump --version" &> /dev/null; then
    echo "Error: tcpdump not found on device. Please install tcpdump to continue."
    exit 1
fi

# Check if there is an argument provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <com.app.example>"
    exit 1
fi

app_name="$1"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGS_DIR="./logs/$app_name/$TIMESTAMP"

# Create output directory
mkdir -p "$LOGS_DIR"

# Device paths
STRACE_LOG="/data/local/tmp/strace.log"
TCPDUMP_LOG="/data/local/tmp/network.pcap"
LOGCAT_LOG="/data/local/tmp/logcat.log"

echo "----------------------------------"
echo "Starting monitoring for: $app_name"
echo "Output will be saved at: $LOGS_DIR"
echo "----------------------------------"

# Get the process PID
pid=$(adb shell pidof "$app_name")

# just in case if pidof did not work
if [ -z "$pid" ]; then
    pid=$(adb shell ps -A | grep "$app_name" | awk '{print $2}')
fi

if [ -z "$pid" ]; then
    echo "Error: No running process found for '$app_name'"
    exit 1
fi

# Take the last PID if it found more than one
pid=$(echo "$pid" | tail -n 1)
process_info=$(adb shell ps -A | grep "$pid")

echo "Found process:"
echo "$process_info"
echo "----------------------------------"

# Clear previous logs
adb shell "su -c '> $STRACE_LOG'"
adb shell "su -c '> $LOGCAT_LOG'"
adb shell "su -c 'rm -f $TCPDUMP_LOG'"

# Start logcat capture in background
echo "Starting logcat capture..."
adb logcat -c  # Clear existing logcat
adb logcat -v threadtime > "$LOGS_DIR/logcat.log" &
LOGCAT_PID=$!

# Start network capture in background (requires root)
echo "Starting network capture..."
adb shell "su -c '/data/local/tmp/tcpdump -i any -w $TCPDUMP_LOG'" &
TCPDUMP_PID=$!

# Start strace capture in background (requires root)
echo "Starting strace capture..."
adb shell "su -c 'strace -p $pid -tt -T -v -o $STRACE_LOG'" &
STRACE_PID=$!

# Wait for some time (interact with the app)
echo "Monitoring for 120 seconds..."
sleep 120

# Stop all captures
echo "Stopping monitoring..."
kill $STRACE_PID 2>/dev/null
kill $TCPDUMP_PID 2>/dev/null
kill $LOGCAT_PID 2>/dev/null

# Pull all log files from device
echo "Collecting logs..."
adb pull $STRACE_LOG "$LOGS_DIR/strace.log"
adb pull $TCPDUMP_LOG "$LOGS_DIR/network.pcap"
# Logcat was saved directly to logs folder

# Clean up device logs
adb shell "su -c 'rm $STRACE_LOG $TCPDUMP_LOG'"

# Compress the captured files
echo "Compressing logs..."
tar -czf "$LOGS_DIR.tar.gz" -C "$LOGS_DIR" .

echo "----------------------------------"
echo "Monitoring complete!"
echo "Strace log: $LOGS_DIR/strace.log"
echo "Network capture: $LOGS_DIR/network.pcap"
echo "Logcat output: $LOGS_DIR/logcat.log"
echo "Compressed archive: $LOGS_DIR.tar.gz"
echo "----------------------------------"