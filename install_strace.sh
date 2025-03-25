#!/bin/bash

# Dependencies: sudo apt install autoconf automake libtool pkg-config wget

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check ADB
if ! command -v adb &> /dev/null; then
    echo -e "${RED}Error: ADB not found. Install Android SDK platform-tools.${NC}"
    exit 1
fi

# Check NDK
if [ -z "$NDK_HOME" ]; then
    echo -e "${RED}Error: Android NDK not configured. Set NDK_HOME.${NC}"
    exit 1
fi

# Device check
if ! adb get-state &> /dev/null; then
    echo -e "${RED}Error: No device connected.${NC}"
    exit 1
fi

# Target dir on device
TARGET_DIR="/data/local/tmp"

# Detect architecture
ARCH=$(adb shell uname -m)
case $ARCH in
    armv7*)   TARGET="armv7a-linux-androideabi";;
    aarch64|armv8l) TARGET="aarch64-linux-android";;
    x86_64)   TARGET="x86_64-linux-android";;
    i*86)     TARGET="i686-linux-android";;
    *)        echo -e "${RED}Unsupported arch: $ARCH${NC}"; exit 1;;
esac
echo -e "${GREEN}Target: $TARGET${NC}"

# Set up NDK toolchain
export TOOLCHAIN="$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
export CC="$TOOLCHAIN/bin/${TARGET}21-clang"
export CXX="$TOOLCHAIN/bin/${TARGET}21-clang++"
export STRIP="$TOOLCHAIN/bin/llvm-strip"

# Build strace
echo -e "${YELLOW}Building strace from source...${NC}"
wget https://github.com/strace/strace/releases/download/v6.7/strace-6.7.tar.xz || {
    echo -e "${RED}Failed to download strace${NC}"; exit 1
}
tar -xf strace-6.7.tar.xz || exit 1
cd strace