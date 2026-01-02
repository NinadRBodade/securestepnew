#!/bin/bash

echo "🔍 Testing SOS Flow on WiFi Network (192.168.1.59)"
echo "=================================================="
echo ""

echo "1️⃣ Testing Backend Server..."
curl -s http://192.168.1.59:5001/health | jq .
echo ""

echo "2️⃣ Testing SOS Routes (Public Access)..."
curl -s http://192.168.1.59:5001/api/sos/police/dashboard | jq '.status, .data.events | length'
echo ""

echo "3️⃣ Current SOS Events Count:"
curl -s http://192.168.1.59:5001/api/sos/police/dashboard | jq '.data.events | length'
echo ""

echo "✅ All tests completed!"
echo ""
echo "🌐 Access URLs:"
echo "   Police Portal: http://192.168.1.59:8080/police_portal/"
echo "   Agent Portal:  http://192.168.1.59:8080/agent_portal/"
echo "   Backend API:   http://192.168.1.59:5001"
echo ""
echo "📱 Mobile App Configuration:"
echo "   IP Address: 192.168.1.59"
echo "   Port: 5001"
echo ""
echo "🔄 Next Steps:"
echo "   1. Log out from mobile app"
echo "   2. Log back in (this sets the auth token)"
echo "   3. Trigger SOS from mobile"
echo "   4. Check police portal at http://192.168.1.59:8080/police_portal/"
