#!/bin/bash

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo "Error: ADB not found. Please ensure the Android SDK is installed and configured correctly."
    exit 1
fi

filename="device_info.log"

echo "Checking connected devices..." > $filename
adb devices                         | tee -a $filename
echo "\nProduct/Device alias:"      | tee -a $filename
adb shell getprop ro.product.device | tee -a $filename
echo "\nDevice Model:"              | tee -a $filename
adb shell getprop ro.product.model  | tee -a $filename
echo "\nProduct Name:"              | tee -a $filename
adb shell getprop ro.product.name   | tee -a $filename
echo "\nManufactorer:"              | tee -a $filename
adb shell getprop ro.product.manufacturer
