#!/bin/bash

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo "Error: ADB not found. Please ensure the Android SDK is installed and configured correctly."
    exit 1
fi

if ! command -v adb shell ls /sys/kernel/tracing &> /dev/null; then
    echo "Error: strace not found. Please install strace to continue."
    exit 1
fi

# Check if argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <com.app.example>"
    exit 1
fi

app_name="$1"

echo "Searching for process: $app_name"
echo "----------------------------------"

# Get the PID of the process
pid=$(adb shell ps -A | grep "$process_name" | awk '{print $2}')

if [ -z "$pid" ]; then
    echo "Error: No running process found matching '$process_name'"
    exit 1
fi

# Take the last PID
pid=$(echo "$pid" | tail -n 1)
process_info=$(adb shell ps -A | grep "$pid")

echo "Found process:"
echo "$process_info"
echo "----------------------------------"
echo "Starting ftrace on PID $pid..."
echo "Output will be saved to /data/local/tmp/strace.log (device)"


# Enable syscall tracing for this PID
adb shell su -c "echo $pid > /sys/kernel/tracing/set_ftrace_pid"
adb shell su -c "echo 1 > /sys/kernel/tracing/events/syscalls/enable"
adb shell su -c "echo 1 > /sys/kernel/tracing/tracing_on"

# Wait for some time (or interact with the app)
sleep 60

# Stop and save logs
adb shell su -c "echo 0 > /sys/kernel/tracing/tracing_on"
adb shell su -c "cat /sys/kernel/tracing/trace > /data/local/tmp/chrome_ftrace.log"
adb pull /data/local/tmp/chrome_ftrace.log
# save it
adb shell su -c "cat /sys/kernel/tracing/trace > /data/local/tmp/ftrace.log"
mkdir $app_name
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
adb pull /data/local/tmp/ftrace.log "./$app_name/ftrace_${TIMESTAMP}.log"


