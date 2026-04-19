# 🚨 SOS Alert System - Quick Testing Guide

## 🎯 What Was Fixed

**Problem:** SOS alerts from mobile app didn't appear in police portal
**Root Cause:** Police portal was hardcoded to connect to `192.168.1.59:5001`, but when accessed via `localhost:8080`, it couldn't reach that address for real-time Socket.IO events

**Solution:** Made police portal use dynamic backend URL based on current hostname

---

## ✅ How to Test

### Prerequisites
- Backend running: `npm start` in `backend/` directory
- Portal server running: `npm start` in `backend/` directory (or running `portal-server.js`)
- At least one user account to test with

### Test Steps

#### 1️⃣ Open Police Portal
```
URL: http://localhost:8080/police_portal/
Press F12 to open Developer Tools → Console tab
```

**Expected Console Output:**
```
🚀 Police Dashboard initializing...
   API URL: http://localhost:5001/api
   Socket URL: http://localhost:5001
🔌 Connecting to Socket.IO at: http://localhost:5001
✅ Connected to server at: http://localhost:5001
🔌 Socket ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
📍 Joined police room for alerts
✅ Loaded 0 alerts
```

#### 2️⃣ Send SOS Alert from Mobile App
1. Log in to resident account
2. Navigate to "SOS Alert" screen
3. Select emergency type (e.g., "Fire")
4. Add description: "Test SOS alert"
5. Tap "SEND SOS ALERT"
6. Grant location permission

**Expected App Console Output:**
```
🔄 Sending SOS to: http://localhost:5001/api/sos
🔑 Token: eyJhbGciOiJIUzI1NiIs...
✅ SOS sent to server successfully
```

#### 3️⃣ Verify on Police Portal
Watch the police portal console for:
```
🚨 NEW SOS ALERT received on police:sos-alert: {sosId: "SOS...", ...}
```

And check the UI for:
- ✅ New alert card appears in the list
- ✅ Sound notification plays 🔔
- ✅ Browser notification appears
- ✅ Map marker appears at location
- ✅ Active alert count increases

---

## 🔍 Debugging Tips

### Check 1: Backend Health
```bash
# In terminal
curl http://localhost:5001/health

# Expected response:
# {"status":"OK","message":"Backend running"}
```

### Check 2: See SOS Events in Database
```bash
# In terminal (if MongoDB is available)
mongo
> db.sosevents.find().limit(5)
```

### Check 3: Monitor Backend Logs
```bash
# While backend is running, watch for these messages when you send SOS:
🚨 SOS TRIGGERED: SOS... - Flat ...
💾 SOS saved to MongoDB: SOS...
📡 Emitting SOS alert...
✅ Emitted police:sos-alert to police room
```

### Check 4: Browser Network Tab
1. Open police portal
2. Press F12 → Network tab
3. Filter for "socket.io"
4. You should see a WebSocket connection to localhost:5001
5. Color should be green (successful)

---

## 📊 Quick Test Checklist

After sending SOS, verify ALL of these:

- [ ] Backend logs show "🚨 SOS TRIGGERED"
- [ ] Backend logs show "✅ Emitted police:sos-alert"
- [ ] Police portal console shows "🚨 NEW SOS ALERT received"
- [ ] Police portal shows new alert card in list
- [ ] Alert displays: SOS ID, resident name, flat, location
- [ ] Sound plays when alert arrives
- [ ] Browser notification appears
- [ ] Map shows marker at location
- [ ] "Active Alerts" counter increases
- [ ] Alert status filter works

---

## 🐛 Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Console shows "192.168.1.59" not "localhost" | Browser cached old config | Clear cache: Ctrl+Shift+Del → Reload |
| "❌ Connection error" in console | Backend not running on 5001 | Start backend: `npm start` |
| Police portal won't load | Portal server not running | Start portal server: `npm start` in backend/ |
| No "NEW SOS ALERT received" message | Socket.IO event not sent | Check backend logs for "Emitted" message |
| Alert appears but no sound | Browser has sound muted | Unmute browser in tab settings |
| Alert doesn't appear in list | Frontend rendering issue | Reload police portal page |

---

## 📱 Test Multiple Times

1. **First test:** Single SOS alert
2. **Second test:** Two SOS alerts in quick succession
3. **Third test:** Multiple emergency types
4. **Fourth test:** From different devices (if applicable)

---

## 🎯 Success Criteria

✅ **PASS** if ALL are true:
- SOS sent from app
- Backend saves to database
- Backend emits Socket.IO event
- Police portal receives event in real-time
- Alert displays immediately (< 1 second)
- Alert has all details: ID, name, flat, location, type

❌ **FAIL** if ANY are missing:
- Alert doesn't appear
- Alert appears after manual refresh (delayed)
- Alert missing information
- No sound notification
- No browser notification

---

## 📞 Support

If tests fail:
1. Check the `SOS_FIX_SUMMARY.md` file for detailed troubleshooting
2. Review backend logs for error messages
3. Check browser console (F12) for Socket.IO errors
4. Verify all servers are running on correct ports

---

**Last Updated:** 2024-04-19
**Status:** Ready for Testing ✅
