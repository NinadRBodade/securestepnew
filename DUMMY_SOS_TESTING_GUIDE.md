# 🧪 Dummy SOS Testing Guide

## Overview
Testing buttons have been added to both the **Police Portal** and **Admin Portal** to create dummy SOS alerts for testing and demonstration purposes.

---

## 🚓 Police Portal Testing (http://localhost:8080/police_portal/)

### Test Buttons Location
In the top navigation bar, next to the date/time, you'll find three purple test buttons:

1. **🧪 Dummy SOS** - Creates a single test alert
2. **🧪 ×3 SOS** - Creates 3 test alerts with 500ms delay between them
3. **🧹 Clear All** - Deletes all SOS events from the database

### How to Use

#### Create a Single Test SOS Alert
1. Click the **"🧪 Dummy SOS"** button
2. A random emergency type will be selected (Fire, Medical, Theft, etc.)
3. A random flat number will be assigned
4. Within 1 second, you should see:
   - ✅ Alert appears in the list
   - 🔔 Sound notification plays
   - 🔔 Browser notification appears
   - 📍 Map marker appears at a random Mumbai location

#### Create Multiple Test SOS Alerts
1. Click the **"🧪 ×3 SOS"** button
2. Creates 3 alerts with 500ms delay between each
3. Great for testing multiple alerts at once

#### Clear All Alerts
1. Click the **"🧹 Clear All"** button
2. Confirm when prompted
3. All alerts are immediately removed from database and UI

---

## 👨‍💼 Admin Portal Testing (http://localhost:8080/admin_portal/)

### Test Buttons Location
In the top header bar, right after the status badge and before the user menu, you'll find:

1. **🧪 Dummy SOS** - Creates a single test alert
2. **🧹 Clear All** - Deletes all SOS events

### How to Use
Same as Police Portal, click buttons to create or clear test alerts.

---

## 📱 Mobile App (Guard Side - Port 60417)

Currently, the mobile app does NOT have built-in dummy SOS buttons. Instead:

### Option 1: Create via Police Portal
1. Go to Police Portal
2. Click "🧪 Dummy SOS"
3. Alert appears on Guard's "SOS Dashboard" in the mobile app in real-time

### Option 2: Use Postman/cURL

#### Create Dummy SOS via cURL
```bash
curl -X POST "http://localhost:5001/api/sos/test/dummy?type=Fire&flat=A101"
```

**Response:**
```json
{
  "status": "success",
  "message": "Dummy SOS created successfully",
  "data": {
    "sosEvent": {
      "sosId": "SOS1716664928625...",
      "triggeredBy": {
        "userId": "test-user-123",
        "name": "Test Resident 45",
        "email": "test1234@example.com",
        "phone": "+919876543210",
        "role": "resident"
      },
      "flatNumber": "A101",
      "societyId": "SOC-TEST-001",
      "description": "Fire: Test alert for demonstration",
      "location": {
        "latitude": 19.0765,
        "longitude": 72.8789,
        "address": "A101, Test Society, Mumbai"
      },
      "status": "active",
      "timestamp": "2024-04-19T10:30:45.123Z"
    }
  }
}
```

#### Clear All SOS via cURL
```bash
curl -X DELETE "http://localhost:5001/api/sos/test/clear-all"
```

**Response:**
```json
{
  "status": "success",
  "message": "Cleared 5 SOS events",
  "data": {
    "deletedCount": 5
  }
}
```

---

## 🎯 Testing Scenarios

### Scenario 1: Test Real-Time Updates
1. Open Police Portal in one browser tab
2. Open Guard Dashboard in the mobile app (or simulator)
3. Click "🧪 Dummy SOS" in Police Portal
4. **Expected:** Alert appears instantly in both Police Portal and Guard Dashboard

### Scenario 2: Test Multiple Alerts
1. Click "🧪 ×3 SOS" in Police Portal
2. **Expected:** Three alerts appear with 500ms delay between each
3. Verify all details are correct and unique

### Scenario 3: Test Sound & Notifications
1. Ensure browser has sound enabled
2. Click "🧪 Dummy SOS"
3. **Expected:**
   - Sound notification plays
   - Browser notification appears (if permission granted)
   - Visual alert on page

### Scenario 4: Test Cleanup
1. Create several dummy alerts
2. Click "🧹 Clear All"
3. Confirm deletion when prompted
4. **Expected:** All alerts removed from database and UI
5. Verify other portals (Admin, Guards) also show no alerts

---

## 📊 Test Data Generated

Each dummy SOS creates:
- **Unique SOS ID**: `SOS${timestamp}${random}`
- **Random Emergency Type**: Fire, Medical, Theft, Suspicious Person, Violence, Other
- **Random Flat Number**: A101-G708
- **Random Location**: Within 0.05° of Mumbai center (lat: 19.0760, lon: 72.8777)
- **Test User**: Auto-generated test resident name
- **Blockchain Hash**: Generated for integrity verification

---

## 🔧 API Endpoints for Testing

### Create Dummy SOS
**Endpoint:** `POST /api/sos/test/dummy`

**Query Parameters:**
- `type` (optional): Emergency type (Fire, Medical, etc.)
- `flat` (optional): Flat number (A101, etc.)
- `society` (optional): Society ID (default: SOC-TEST-001)

**Example:**
```
POST http://localhost:5001/api/sos/test/dummy?type=Fire&flat=A101
```

**Response:** 201 Created
```json
{
  "status": "success",
  "message": "Dummy SOS created successfully",
  "data": { ... }
}
```

### Clear All SOS
**Endpoint:** `DELETE /api/sos/test/clear-all`

**Response:** 200 OK
```json
{
  "status": "success",
  "message": "Cleared 5 SOS events",
  "data": {
    "deletedCount": 5
  }
}
```

---

## 🐛 Troubleshooting

### Buttons Not Appearing
- **Solution:** Clear browser cache (Ctrl+Shift+Delete)
- **Or:** Reload page (Ctrl+R or F5)

### Dummy SOS Not Appearing
- **Check:** Backend is running (`npm start` in backend folder)
- **Check:** Backend is on port 5001 (`http://localhost:5001/health` should return OK)
- **Check:** Browser console for errors (F12 → Console tab)

### Sound Not Playing
- **Check:** Browser has sound enabled
- **Check:** System volume is not muted
- **Check:** Browser notification permission is granted

### Test Buttons Working but Alert Not on Guard Dashboard
- **Check:** Guard is logged in and on SOS Dashboard screen
- **Check:** Guard's Socket.IO connection is active (check backend logs for "joined guards room")

---

## 📝 What Gets Tested

✅ **Real-time Socket.IO broadcast**
- Alerts appear instantly on all connected clients

✅ **Sound and browser notifications**
- Audio feedback works
- OS-level notifications appear

✅ **Map functionality**
- Markers appear at correct coordinates
- Location data is accurate

✅ **Alert details display**
- All information shows correctly (SOS ID, name, flat, type, location)

✅ **Alert filtering**
- Filter buttons work with test alerts

✅ **Data integrity**
- Blockchain hash generated and stored

✅ **Database operations**
- CRUD operations work correctly
- Clearing data works properly

---

## ✅ Recommended Testing Flow

1. **Start Fresh**
   - Clear all SOS: Click "🧹 Clear All"

2. **Create Single Alert**
   - Click "🧪 Dummy SOS"
   - Verify alert appears with all details

3. **Create Multiple Alerts**
   - Click "🧪 ×3 SOS"
   - Verify three unique alerts appear

4. **Test Cleanup**
   - Click "🧹 Clear All"
   - Confirm all alerts deleted

5. **Test on Mobile App**
   - Repeat steps 2-4 while watching Guard Dashboard
   - Verify alerts appear in real-time on mobile

---

## 🚀 When to Use Dummy SOS

- ✅ Testing before production deployment
- ✅ Demo purposes to stakeholders
- ✅ Load testing (create multiple alerts)
- ✅ Training new users
- ✅ UI/UX verification
- ✅ Real-time notification testing
- ✅ Sound and notification testing

---

## ⚠️ Important Notes

1. **Test Only** - These endpoints are for testing only
2. **No Actual Emergency** - Dummy alerts are marked as test data
3. **Temporary** - Data is stored in MongoDB but can be cleared anytime
4. **Monitoring** - Backend logs show all dummy SOS creation with 🧪 marker
5. **Production** - Consider disabling these endpoints in production

---

**Last Updated:** 2024-04-19  
**Status:** Ready for Testing ✅
