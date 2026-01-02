#!/bin/bash

# Society Safety App - Network Configuration Helper

echo "=================================="
echo "  Society Safety App - Backend Info"
echo "=================================="
echo ""

# Get Mac's IP address
MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)

if [ -z "$MAC_IP" ]; then
    echo "❌ Could not detect Mac IP address"
    echo "   Make sure you're connected to WiFi"
    exit 1
fi

echo "✅ Your Mac's IP Address: $MAC_IP"
echo ""
echo "📱 Mobile App Configuration:"
echo "   - App should connect to: http://$MAC_IP:5001/api"
echo ""

# Check if backend is running
if lsof -i :5001 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✅ Backend server is RUNNING on port 5001"
    
    # Test backend health
    if curl -s http://localhost:5001/health >/dev/null 2>&1; then
        echo "✅ Backend health check: OK"
        
        # Test from network IP
        if curl -s http://$MAC_IP:5001/health >/dev/null 2>&1; then
            echo "✅ Backend accessible from network: YES"
            echo ""
            echo "🎉 Everything is working!"
            echo ""
            echo "📱 On your phone:"
            echo "   1. Make sure phone and Mac are on SAME WiFi"
            echo "   2. Open the Society Safety app"
            echo "   3. Try to login/register"
            echo ""
            echo "If still not working, check:"
            echo "   - Both devices on same WiFi network"
            echo "   - Mac firewall not blocking port 5001"
        else
            echo "⚠️  Backend NOT accessible from network IP"
            echo "   This means your phone won't be able to connect"
            echo ""
            echo "🔧 Fix: Check Mac firewall settings"
            echo "   System Settings → Network → Firewall"
        fi
    else
        echo "⚠️  Backend not responding to health check"
    fi
else
    echo "❌ Backend server is NOT running"
    echo ""
    echo "🔧 To start the backend:"
    echo "   cd backend"
    echo "   npm start"
fi

echo ""
echo "=================================="
echo ""
echo "Current API Config in App:"
echo "   macIP = '$MAC_IP'"
echo ""
echo "⚠️  If your Mac IP changes, update:"
echo "   lib/config/api_config.dart"
echo "   Change: static const String macIP = '$MAC_IP';"
echo "=================================="
