# 🧪 Dummy SOS - Quick Reference Card

## 🚨 Three Ways to Create Test Alerts

### Way 1: Police Portal Buttons
```
URL: http://localhost:8080/police_portal/

Buttons in top nav bar:
  🧪 Dummy SOS    → Creates 1 alert
  🧪 ×3 SOS       → Creates 3 alerts (500ms delay)
  🧹 Clear All    → Delete all alerts
```

### Way 2: Admin Portal Buttons
```
URL: http://localhost:8080/admin_portal/

Buttons in header:
  🧪 Dummy SOS    → Creates 1 alert
  🧹 Clear All    → Delete all alerts
```

### Way 3: API Endpoints (cURL)
```bash
# Create single alert
curl -X POST "http://localhost:5001/api/sos/test/dummy"

# With custom type and flat
curl -X POST "http://localhost:5001/api/sos/test/dummy?type=Fire&flat=A101"

# Clear all alerts
curl -X DELETE "http://localhost:5001/api/sos/test/clear-all"
```

---

## 📊 Generated Test Data

Each dummy SOS includes:
- ✅ Unique SOS ID
- ✅ Random emergency type (6 types)
- ✅ Random flat number
- ✅ Random Mumbai location
- ✅ Test user name and phone
- ✅ Blockchain integrity hash
- ✅ Auto broadcast to all portals

---

## 🎯 Emergency Types
- Fire
- Medical Emergency
- Suspicious Person
- Theft
- Violence
- Other

---

## 🏠 Random Flat Numbers
A101, A102, B203, C304, D405, E506, F607, G708

---

## 🗺️ Location Range
Mumbai area (~0.05° radius):
- Latitude: 19.0760 ±0.025
- Longitude: 72.8777 ±0.025

---

## 🔄 Real-Time Delivery

```
Button Click (Frontend)
    ↓
API Call (Backend)
    ↓
Socket.IO Broadcast
    ↓
All Connected Portals
    ↓
UI Update + Sound + Notification
```

**Speed:** < 1 second from click to display

---

## 📱 Where Alerts Appear

✅ **Police Portal**
- Alert list
- Map markers
- Statistics
- Notifications

✅ **Admin Portal**
- SOS alerts section
- Alert cards
- Details modal

✅ **Mobile App (Guard)**
- SOS Dashboard
- Real-time stream
- Guard response options

---

## 🧪 Quick Test
```
1. Go to: http://localhost:8080/police_portal/
2. Click: 🧪 Dummy SOS
3. See: Alert appears instantly
4. Hear: Sound notification
5. Done! ✅
```

---

## 🗑️ Cleanup
```
1. Click: 🧹 Clear All
2. Confirm: Yes
3. Result: All alerts deleted ✅
```

---

## 🐛 If Not Working

**Check:** Backend running?
```bash
curl http://localhost:5001/health
# Should return: {"status":"OK","message":"Backend running"}
```

**Check:** Browser console (F12)
```
Look for: ✅ Dummy SOS created: SOS...
Or error messages
```

**Check:** Backend logs
```
Look for: 🧪 DUMMY SOS CREATED: SOS...
```

---

## 📝 Advanced Usage

### Create Multiple Alerts via Script
```javascript
// Create 10 alerts
for(let i = 0; i < 10; i++) {
    await fetch('http://localhost:5001/api/sos/test/dummy', {method: 'POST'});
    await new Promise(r => setTimeout(r, 200));
}
```

### Create with Specific Type
```bash
curl -X POST "http://localhost:5001/api/sos/test/dummy?type=Medical%20Emergency&flat=C304"
```

### Check Cleared Count
```bash
curl -X DELETE "http://localhost:5001/api/sos/test/clear-all"
# Response shows: {"deletedCount": 5}
```

---

## ✅ Testing Checklist

- [ ] Backend running on port 5001
- [ ] Police portal loading on port 8080
- [ ] Admin portal loading on port 8080
- [ ] Test buttons visible
- [ ] Click creates alert (< 1 second)
- [ ] Sound notification plays
- [ ] Browser notification shows
- [ ] Map marker appears
- [ ] Clear button removes all
- [ ] Mobile app sees alerts (if running)

---

## 🎥 Common Test Scenarios

### Test 1: Basic Functionality
1. Click "🧪 Dummy SOS"
2. Alert appears ✅

### Test 2: Multiple Alerts
1. Click "🧪 ×3 SOS"
2. Three alerts appear ✅

### Test 3: Cleanup
1. Click "🧹 Clear All"
2. Confirm deletion
3. All gone ✅

### Test 4: Real-Time Sync
1. Open police portal in Tab A
2. Open admin portal in Tab B
3. Create alert in Tab A
4. Appears in Tab B instantly ✅

### Test 5: Mobile Integration
1. Open Police Portal in browser
2. Open Guard Dashboard on phone
3. Create alert in Police Portal
4. Appears on phone instantly ✅

---

## 🚀 Next Steps

1. **Test in Browser**: Click the test buttons
2. **Test on Mobile**: Create alerts and watch mobile app
3. **Test Sound**: Verify notifications work
4. **Load Test**: Click "×3" multiple times
5. **Production**: Remove /test/ endpoints before deploying

---

## 📞 API Reference

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/sos/test/dummy` | Create test alert |
| DELETE | `/api/sos/test/clear-all` | Delete all alerts |

---

**Version:** 1.0  
**Last Updated:** 2024-04-19  
**Status:** ✅ Ready to Use
