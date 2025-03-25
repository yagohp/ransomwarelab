#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Config
TARGET_DIR="/data/local/tmp"
WORK_DIR="$HOME/android_tcpdump_build"

# Architecture detection
get_arch() {
    case $(adb shell uname -m) in
        armv7*)    echo "armv7a-linux-androideabi";;
        aarch64)   echo "aarch64-linux-android";;
        armv8l)    echo "aarch64-linux-android";;
        x86_64)    echo "x86_64-linux-android";;
        i*86)      echo "i686-linux-android";;
        *)         echo "unknown";;
    esac
}

# Apply critical Android patches
apply_patches() {
    cd "$WORK_DIR/tcpdump" || return 1
    
    # 1. Completely disable getservent functionality
    sed -i 's/^#error netdb.h and getservent.h are incompatible/\/\/ DISABLED for Android: #error netdb.h and getservent.h are incompatible/' getservent.h
    
    # 2. Create custom config.h with Android-specific settings
    cat > config.h << 'EOF'
#define HAVE_GETSERVENT 0
#define HAVE_GETSERVBYNAME 0
#define HAVE_GETSERVBYPORT 0
#define HAVE_DECL_GETSERVENT 0
#define PCAP_IS_AT_LEAST_1_0_0 1
EOF
    
    cd ..
}

# Verify tools
verify_tools() {
    local missing=()
    for cmd in adb git automake autoconf make; do
        if ! command -v $cmd >/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing: ${missing[*]}${NC}"
        echo "Install with:"
        [[ "$OSTYPE" == "linux-gnu"* ]] && echo "  sudo apt install ${missing[*]}"
        [[ "$OSTYPE" == "darwin"* ]] && echo "  brew install ${missing[*]}"
        exit 1
    fi
}

# Main installation
echo -e "${GREEN}=== Android tcpdump Installer ===${NC}"

# Verify environment
verify_tools
if ! adb get-state >/dev/null; then
    echo -e "${RED}Connect your Android device first${NC}"
    exit 1
fi

# Detect architecture
TARGET=$(get_arch)
if [ "$TARGET" == "unknown" ]; then
    echo -e "${RED}Unsupported architecture: $(adb shell uname -m)${NC}"
    exit 1
fi
echo -e "Detected architecture: ${GREEN}$TARGET${NC}"

# Prepare workspace
echo -e "${YELLOW}Preparing build environment...${NC}"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

# Get latest sources [OFFICIAL]
echo -e "${YELLOW}Downloading sources...${NC}"
git clone --depth 1 https://github.com/the-tcpdump-group/libpcap.git
git clone --depth 1 https://github.com/the-tcpdump-group/tcpdump.git

# Build libpcap
echo -e "${YELLOW}Building libpcap...${NC}"
cd libpcap
./autogen.sh 2>/dev/null || autoreconf -f -i
./configure --host="$TARGET" --disable-shared >/dev/null
make -j$(nproc) >/dev/null
cd ..

# Apply Android patches before building tcpdump
apply_patches

# Build tcpdump
echo -e "${YELLOW}Building tcpdump...${NC}"
cd tcpdump
./autogen.sh 2>/dev/null || autoreconf -f -i
./configure --host="$TARGET" \
    LDFLAGS="-L$WORK_DIR/libpcap" \
    CPPFLAGS="-I$WORK_DIR/libpcap" >/dev/null
make -j$(nproc)
cd ..

# Install to device
echo -e "${YELLOW}Installing to device...${NC}"
adb push "$WORK_DIR/tcpdump/tcpdump" "$TARGET_DIR/tcpdump"
adb shell chmod 755 "$TARGET_DIR/tcpdump"

# Verify
if adb shell "$TARGET_DIR/tcpdump --version" >/dev/null 2>&1; then
    echo -e "${GREEN}Installation successful!${NC}"
    echo -e "\nUsage:"
    echo -e "  adb shell $TARGET_DIR/tcpdump -i any -w /sdcard/capture.pcap"
else
    echo -e "${RED}Installation failed${NC}"
    exit 1
fi