#!/bin/bash

# Default options
WRITABLE_SYSTEM="-writable-system"
NO_SNAPSHOT="-no-snapshot"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -avd)
            AVD_NAME="$2"
            shift
            ;;
        -no-writable-system)
            WRITABLE_SYSTEM=""
            ;;
        -snapshot)
            NO_SNAPSHOT=""
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
    shift
done

# Check if the AVD name is provided
if [ -z "$AVD_NAME" ]; then
    echo "Usage: $0 -avd <AVD_NAME> [-no-writable-system] [-snapshot]"
    exit 1
fi

# Start the emulator with the specified options
echo "Starting emulator with AVD: $AVD_NAME"
emulator -avd "$AVD_NAME" $WRITABLE_SYSTEM $NO_SNAPSHOT