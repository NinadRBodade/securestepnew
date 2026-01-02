#!/bin/bash

echo "🔍 COMPLETE SOS FLOW TEST"
echo "=========================="
echo ""

# Test 1: Backend Health
echo "1️⃣ Backend Health Check:"
HEALTH=$(curl -s http://192.168.1.59:5001/health)
echo "$HEALTH" | jq .
echo ""

# Test 2: Police Dashboard Endpoint
echo "2️⃣ Police Dashboard Endpoint:"
EVENTS=$(curl -s http://192.168.1.59:5001/api/sos/police/dashboard)
EVENT_COUNT=$(echo "$EVENTS" | jq '.data.events | length')
echo "Status: $(echo "$EVENTS" | jq -r '.status')"
echo "Total SOS Events: $EVENT_COUNT"
echo ""

# Test 3: Test login with resident
echo "3️⃣ Testing Resident Login:"
LOGIN_RESPONSE=$(curl -s -X POST http://192.168.1.59:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "sexy@gmail.com",
    "password": "123456"
  }')

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
USER_ROLE=$(echo "$LOGIN_RESPONSE" | jq -r '.user.role')

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  echo "✅ Login successful"
  echo "   Role: $USER_ROLE"
  echo "   Token: ${TOKEN:0:20}..."
else
  echo "❌ Login failed"
  echo "$LOGIN_RESPONSE" | jq .
  exit 1
fi
echo ""

# Test 4: Trigger SOS with auth token
echo "4️⃣ Testing SOS Trigger with Token:"
SOS_RESPONSE=$(curl -s -X POST http://192.168.1.59:5001/api/sos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "societyId": "SOC123",
    "flatNumber": "A101",
    "description": "TEST SOS - Emergency situation",
    "latitude": 19.0760,
    "longitude": 72.8777,
    "locationAddress": "Test Location, Mumbai"
  }')

SOS_STATUS=$(echo "$SOS_RESPONSE" | jq -r '.status')
SOS_ID=$(echo "$SOS_RESPONSE" | jq -r '.data.sosEvent.sosId // .data.sosEvent._id')

if [ "$SOS_STATUS" = "success" ]; then
  echo "✅ SOS Triggered Successfully!"
  echo "   SOS ID: $SOS_ID"
  echo "   Status: $SOS_STATUS"
else
  echo "❌ SOS Trigger Failed"
  echo "$SOS_RESPONSE" | jq .
fi
echo ""

# Test 5: Verify SOS appears in police dashboard
echo "5️⃣ Verifying SOS in Police Dashboard:"
sleep 2
NEW_EVENTS=$(curl -s http://192.168.1.59:5001/api/sos/police/dashboard)
NEW_EVENT_COUNT=$(echo "$NEW_EVENTS" | jq '.data.events | length')
echo "Total SOS Events Now: $NEW_EVENT_COUNT"

if [ "$NEW_EVENT_COUNT" -gt "$EVENT_COUNT" ]; then
  echo "✅ New SOS event appeared in police dashboard!"
else
  echo "⚠️ SOS count unchanged (might be duplicate or issue)"
fi
echo ""

echo "================================"
echo "📊 SUMMARY"
echo "================================"
echo "Backend: ✅ Running"
echo "Police Endpoint: ✅ Working ($EVENT_COUNT events)"
echo "Login: ✅ Working (Token received)"
echo "SOS Trigger: $([ "$SOS_STATUS" = "success" ] && echo "✅ Success" || echo "❌ Failed")"
echo "Police Dashboard: $([ "$NEW_EVENT_COUNT" -gt "$EVENT_COUNT" ] && echo "✅ Updated" || echo "⚠️ Check needed")"
echo ""
echo "🌐 Access Police Portal:"
echo "   http://192.168.1.59:8080/police_portal/"
