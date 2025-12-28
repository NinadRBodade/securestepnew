#!/bin/bash

echo "======================================"
echo "🧪 Backend Integration Test"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base URL
BASE_URL="http://localhost:5000"

echo "Testing: $BASE_URL"
echo ""

# Test 1: Health Check
echo "1️⃣  Testing Health Endpoint..."
response=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/health)
if [ $response -eq 200 ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
else
    echo -e "${RED}❌ Health check failed (Status: $response)${NC}"
fi
echo ""

# Test 2: Register User
echo "2️⃣  Testing User Registration..."
register_response=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Resident",
    "email": "test'$(date +%s)'@test.com",
    "phone": "9999999999",
    "password": "test123",
    "role": "resident"
  }')

if [[ $register_response == *"success"* ]]; then
    echo -e "${GREEN}✅ Registration passed${NC}"
    echo "Response: $register_response" | jq '.' 2>/dev/null || echo "$register_response"
else
    echo -e "${RED}❌ Registration failed${NC}"
    echo "Response: $register_response"
fi
echo ""

# Test 3: Login
echo "3️⃣  Testing User Login..."
login_response=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "resident@demo.com",
    "password": "resident123"
  }')

if [[ $login_response == *"token"* ]]; then
    echo -e "${GREEN}✅ Login passed${NC}"
    TOKEN=$(echo $login_response | jq -r '.data.token' 2>/dev/null)
    echo "Token: ${TOKEN:0:20}..."
else
    echo -e "${RED}❌ Login failed${NC}"
    echo "Response: $login_response"
fi
echo ""

# Test 4: Trigger SOS (no auth)
echo "4️⃣  Testing SOS Alert (Emergency - No Auth)..."
sos_response=$(curl -s -X POST $BASE_URL/api/sos/alert \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test@test.com",
    "userName": "Test User",
    "userRole": "resident",
    "flatNumber": "A-101",
    "latitude": "19.0760",
    "longitude": "72.8777",
    "locationAddress": "Mumbai, Maharashtra",
    "description": "Test Emergency",
    "status": "active"
  }')

if [[ $sos_response == *"success"* ]]; then
    echo -e "${GREEN}✅ SOS Alert passed${NC}"
    ALERT_ID=$(echo $sos_response | jq -r '.alertId' 2>/dev/null)
    echo "Alert ID: $ALERT_ID"
else
    echo -e "${RED}❌ SOS Alert failed${NC}"
    echo "Response: $sos_response"
fi
echo ""

# Test 5: Get SOS Events (requires auth)
if [ ! -z "$TOKEN" ]; then
    echo "5️⃣  Testing Get SOS Events (Auth Required)..."
    get_sos_response=$(curl -s -X GET "$BASE_URL/api/sos/alerts" \
      -H "Authorization: Bearer $TOKEN")
    
    if [[ $get_sos_response == *"success"* ]]; then
        echo -e "${GREEN}✅ Get SOS Events passed${NC}"
        echo "Events count: $(echo $get_sos_response | jq '.data | length' 2>/dev/null)"
    else
        echo -e "${RED}❌ Get SOS Events failed${NC}"
        echo "Response: $get_sos_response"
    fi
else
    echo "5️⃣  Skipping Get SOS Events (No token)"
fi
echo ""

echo "======================================"
echo "🎉 Test Complete!"
echo "======================================"
echo ""
echo "Next Steps:"
echo "1. If all tests passed, your backend is ready!"
echo "2. Start the backend: npm run dev"
echo "3. Test with Flutter app"
echo ""
