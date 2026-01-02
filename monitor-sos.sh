#!/bin/bash

echo "🔍 MONITORING BACKEND FOR SOS REQUESTS"
echo "======================================"
echo ""
echo "Backend is running. Now trigger SOS from your phone."
echo "You should see one of these:"
echo ""
echo "✅ SUCCESS: '🚨 SOS TRIGGERED' message"
echo "❌ NO AUTH: 'Authorization token missing'"
echo "❌ NO REQUEST: Nothing appears (phone not sending)"
echo ""
echo "Watching backend logs..."
echo "Press Ctrl+C to stop"
echo ""

# Get backend process
BACKEND_PID=$(lsof -ti:5001 | head -1)

if [ -z "$BACKEND_PID" ]; then
    echo "❌ Backend not running on port 5001!"
    exit 1
fi

echo "✅ Backend PID: $BACKEND_PID"
echo "📊 Current SOS count: $(curl -s http://192.168.1.59:5001/api/sos/police/dashboard | jq '.data.events | length')"
echo ""
echo "==================== WAITING FOR SOS ===================="
echo ""

# Monitor the terminal where backend is running
# Since we can't directly tail the process output, we'll watch the network
tcpdump -i any -A 'tcp port 5001' 2>/dev/null | grep --line-buffered -E "POST /api/sos|Authorization|SOS|flatNumber" &
TCPDUMP_PID=$!

# Also make a test request every 10 seconds to check if backend is responsive
while true; do
    sleep 10
    CURRENT_COUNT=$(curl -s http://192.168.1.59:5001/api/sos/police/dashboard | jq '.data.events | length')
    echo "[$(date +%H:%M:%S)] Current SOS count: $CURRENT_COUNT"
done

# Cleanup
kill $TCPDUMP_PID 2>/dev/null
