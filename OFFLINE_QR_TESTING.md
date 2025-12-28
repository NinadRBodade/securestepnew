# 🧪 Quick Testing Guide - Offline QR Verification

## ⚡ Quick Start

### 1️⃣ Run the App on Android
```bash
# Make sure Android emulator or device is connected
flutter devices

# Run the app
flutter run
```

### 2️⃣ Test Online QR Scanning (Baseline)

**Steps**:
1. Login as **Guard** (create guard account if needed)
2. Login as **Agent** on another device/browser
3. Agent: Navigate to "My QR Code" screen
4. Guard: Tap "Scan QR" button
5. Guard: Point camera at agent's QR code
6. **Expected**: 
   - Status bar shows "🟢 Online"
   - Scan succeeds
   - Dialog shows "CHECK-IN" or "CHECK-OUT"
   - NO "OFFLINE" badge
   - NO "Will sync" message

### 3️⃣ Test Offline QR Scanning (Main Feature)

**Steps**:
1. Guard: Open QR scanner screen
2. **Turn on Airplane Mode** on guard's device
3. Guard: Verify status bar shows "🔴 Offline"
4. Agent: Show QR code (on screen or printed)
5. Guard: Scan the QR code
6. **Expected**:
   - Scan succeeds (no internet required!)
   - Dialog shows:
     - "CHECK-IN" or "CHECK-OUT"
     - **[📴 OFFLINE]** badge (orange)
     - "✅ Verified"
     - **"Will sync when online"** message
   - Top bar shows badge: **[🔄 1]** (unsynced count)
7. Guard: Scan **same agent again**
8. **Expected**:
   - Action toggles: CHECK-IN → CHECK-OUT
   - Badge updates: **[🔄 2]**

### 4️⃣ Test Auto-Sync

**Steps**:
1. Guard: Have 2-3 offline entries (badge shows [3])
2. **Turn off Airplane Mode**
3. Wait 3-5 seconds
4. **Expected**:
   - Status bar changes: "🔴 Offline" → "🟢 Online"
   - SnackBar appears: **"Synced 3 entries"** (green)
   - Badge disappears: **[🔄 3]** → (gone)
5. Check backend logs:
   ```
   🔄 Synced offline CHECK_IN: John Doe at 2024-01-15T10:30:00.000Z
   🔄 Synced offline CHECK_OUT: John Doe at 2024-01-15T10:35:00.000Z
   ```

### 5️⃣ Test Manual Sync

**Steps**:
1. Guard: Have offline entries with **internet ON**
2. Guard: Tap **[🔄 2]** sync button in top bar
3. **Expected**:
   - Immediate sync starts
   - SnackBar: "Synced 2 entries"
   - Badge clears

### 6️⃣ Test QR Expiry (Security)

**Steps**:
1. Agent: Open "My QR Code" screen
2. Agent: Note "Valid For: 24 hours" indicator
3. **Test Expired QR** (manual):
   - Edit `agent_qr_screen.dart` line 117:
     ```dart
     final expiresAt = issuedAt.add(Duration(seconds: 5)); // Changed from 24 hours
     ```
   - Hot reload (`r` in terminal)
   - Wait 10 seconds
   - Scan QR offline
4. **Expected**:
   - Scan rejected
   - Error: "QR code expired"

---

## 🎯 Expected Behaviors

### ✅ ONLINE Mode
| Action | Result |
|--------|--------|
| Scan QR | Backend verification |
| Status | 🟢 Online |
| Dialog | Normal CHECK-IN/OUT |
| Storage | MongoDB only |
| Badge | None |

### ✅ OFFLINE Mode
| Action | Result |
|--------|--------|
| Scan QR | Local verification |
| Status | 🔴 Offline |
| Dialog | [📴 OFFLINE] badge |
| Storage | SQLite → MongoDB (later) |
| Badge | [🔄 N] unsynced count |

### ✅ Entry/Exit Toggle (Offline)
| Previous | New | Logic |
|----------|-----|-------|
| (None) | CHECK-IN | First scan |
| CHECK-IN | CHECK-OUT | Agent inside |
| CHECK-OUT | CHECK-IN | Agent outside |

---

## 🔍 Debug Checklist

### Issue: "Status Always Shows Online"
- **Fix**: Check `connectivity_plus` permissions
- **Test**: Turn on airplane mode, close/reopen scanner

### Issue: "Offline Scan Shows Error"
- **Check**: QR has `signature` and `expiresAt` fields
- **Fix**: Regenerate QR on agent screen

### Issue: "Sync Button Never Appears"
- **Check**: SQLite database created
- **Debug**: Add `print(await _db.getUnsyncedCount());`

### Issue: "Auto-Sync Doesn't Work"
- **Check**: Token exists (guard logged in)
- **Check**: Backend running on port 5001
- **Test**: Manual sync with button

### Issue: "Badge Doesn't Update"
- **Fix**: Add `await _loadUnsyncedCount();` after scan

---

## 📱 Test Scenarios

### Scenario 1: Network Outage During Shift
```
1. Guard starts shift (online)
2. Network goes down (offline)
3. Guard scans 10 agents (all offline)
4. Network restored (auto-sync)
5. All 10 entries appear in backend
```

### Scenario 2: Multiple Guards Offline
```
1. Guard A scans Agent #1 offline (CHECK-IN)
2. Guard B scans Agent #1 offline (sees CHECK-IN, does CHECK-OUT)
3. Both sync when online
4. Backend reconciles correctly
```

### Scenario 3: Expired QR Rejection
```
1. Agent generates QR (24h expiry)
2. Wait 25 hours (or modify code)
3. Guard scans offline
4. Rejected: "QR code expired"
5. Agent refreshes QR
6. Scan succeeds
```

---

## 🎬 Video Demo Script

Record this to show the feature:

```
🎬 SCENE 1: Online Mode (Baseline)
[Guard opens scanner]
[Status: 🟢 Online]
[Scans agent QR]
[Dialog: "CHECK-IN" - no badges]
"This is normal online mode"

🎬 SCENE 2: Go Offline
[Pull down control center]
[Enable airplane mode]
[Scanner status: 🔴 Offline]
"Network is now off"

🎬 SCENE 3: Offline Scan
[Scan agent QR]
[Dialog: "CHECK-IN [📴 OFFLINE]"]
[Shows "Will sync when online"]
[Badge appears: [🔄 1]]
"Entry saved locally!"

🎬 SCENE 4: Scan Again (Toggle)
[Scan same agent]
[Dialog: "CHECK-OUT [📴 OFFLINE]"]
[Badge: [🔄 2]]
"Toggle works offline"

🎬 SCENE 5: Auto-Sync
[Disable airplane mode]
[Wait 3 seconds]
[Status: 🟢 Online]
[SnackBar: "Synced 2 entries"]
[Badge disappears]
"Auto-synced to backend!"

🎬 SCENE 6: Backend Verification
[Open admin portal]
[Check entry logs]
[Shows both CHECK-IN and CHECK-OUT with offline flag]
"All entries in database ✅"
```

---

## 🐛 Known Limitations

1. **Face verification still requires online** (separate feature)
2. **QR signature is basic SHA-256** (can upgrade to RSA)
3. **No conflict resolution** if agent checked out elsewhere
4. **Manual time manipulation** can bypass expiry (device-dependent)

---

## ✅ Success Criteria

- [ ] Guard can scan QR codes with airplane mode on
- [ ] Offline badge appears in dialog
- [ ] Unsynced count shows in badge
- [ ] Auto-sync triggers when network restored
- [ ] Manual sync button works
- [ ] Entry/exit toggle works offline
- [ ] Expired QR codes rejected
- [ ] Backend receives all synced entries

---

## 📞 Troubleshooting

| Problem | Solution |
|---------|----------|
| Duplicate path_provider error | Already fixed in pubspec.yaml |
| Connectivity package not found | Run `flutter pub get` |
| SQLite errors | Check Android permissions |
| Backend sync fails | Verify token exists, backend running |
| Status always online | Restart app after installing packages |

---

## 🚀 Ready to Test!

Run these commands:
```bash
# 1. Clean build
flutter clean
flutter pub get

# 2. Run on Android
flutter run

# 3. Test all scenarios above
```

**Priority Tests**:
1. ✅ Offline scan (airplane mode)
2. ✅ Auto-sync (turn off airplane mode)
3. ✅ Entry/exit toggle (scan twice)
4. ✅ Unsynced count badge

---

**Status**: ✅ **IMPLEMENTATION COMPLETE - READY TO TEST!**
