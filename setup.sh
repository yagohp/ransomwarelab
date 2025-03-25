#!/bin/bash

# Define Android SDK paths
ANDROID_SDK_ROOT="/home/yago/Android/Sdk"
PLATFORM_TOOLS="$ANDROID_SDK_ROOT/platform-tools"
CMAKE_BIN="$ANDROID_SDK_ROOT/cmake/3.31.6/bin"
CMD_LINE_TOOLS="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
EMULATOR="$ANDROID_SDK_ROOT/emulator"
NDK="$ANDROID_SDK_ROOT/ndk/29.0.13113456"

# Add paths to the PATH variable
export PATH="$PLATFORM_TOOLS:$CMAKE_BIN:$CMD_LINE_TOOLS:$EMULATOR:$NDK:$PATH"
export ANDROID_NDK_HOME="$NDK"

export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
export TARGET=armv7a-linux-androideabi  # Adjust for your target architecture
export API=21  # Minimum API level
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
#./configure --host=$TARGET --prefix=$(pwd)/output
#make

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo "Error: ADB not found. Please ensure the Android SDK is installed and configured correctly."
    exit 1
fi

# Verify ADB is working
echo "Checking connected devices..."
adb devices

# Reminder to refresh the terminal
echo "Environment variables have been updated."
echo "To apply changes to your current terminal, run:"
echo "source $0"