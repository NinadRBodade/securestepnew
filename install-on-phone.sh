#!/bin/bash

# Quick Install Script for Phone
# This will install the APK on your connected Android phone

echo "📱 Society Safety App - Phone Installer"
echo "======================================="
echo ""

# Check if phone is connected
echo "Checking for connected devices..."
adb devices

echo ""
echo "If you see your device listed above, press Enter to install..."
read

echo "Installing app on your phone..."
adb install -r build/app/outputs/flutter-apk/app-release.apk

echo ""
echo "✅ Installation complete!"
echo "The app should now be on your phone's app drawer"
