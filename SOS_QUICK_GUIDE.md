# Quick Start Guide: SOS Alert System

## 🚨 Overview
The SOS Alert System enables residents to send emergency alerts to guards and police with automatic location tracking. Guards can respond in real-time through a dedicated dashboard.

---

## For Residents

### Triggering an SOS Alert

1. **Open the App**
   - Login as a resident

2. **Access SOS**
   - From home screen, tap the **"SOS Alert"** button (red icon)
   - Or use the quick action button on your dashboard

3. **Select Emergency Type**
   - Choose from 6 emergency categories:
     - 🔍 **Suspicious Person** - Unknown individuals loitering
     - 🏥 **Medical Emergency** - Health emergencies
     - 🔥 **Fire** - Fire hazards or smoke
     - 💼 **Theft** - Robbery or burglary in progress
     - ⚠️ **Violence** - Physical altercations
     - 🆘 **Other** - Other emergencies

4. **Add Details (Optional)**
   - Enter additional information about the emergency
   - Example: "Unknown person trying to break into A-234"

5. **Send Alert**
   - Tap **"SEND SOS ALERT"** button
   - Grant location permission if prompted (required)
   - Wait for confirmation message

6. **Confirmation**
   - You'll see:
     - Alert ID
     - Timestamp
     - Your location address
     - Confirmation that guards and police were notified

### Important Notes
- ✅ Your exact GPS location is automatically shared
- ✅ Works offline (alerts queued and sent when online)
- ⚠️ Only use for genuine emergencies
- ⚠️ False alarms may result in penalties

---

## For Guards

### Monitoring SOS Alerts

1. **Access Dashboard**
   - From guard home screen, tap **"SOS Alerts"**
   - Dashboard opens with real-time alerts

2. **View Active Alerts**
   - Red bordered cards = Active emergencies
   - Orange = Acknowledged (in progress)
   - Green = Resolved
   - Filter by status using chips at top

3. **Alert Information Shown**
   - Resident name and flat number
   - Emergency type and description
   - Location address (tap to open in maps)
   - Timestamp (e.g., "5m ago", "2h ago")
   - Current status

### Responding to Alerts

#### Acknowledge an Alert
1. Tap **"Acknowledge"** button on active alert
2. Alert turns orange (acknowledged status)
3. Resident sees that help is on the way

#### Resolve an Alert
1. Tap **"Resolve"** button
2. Enter resolution notes:
   - What action was taken
   - Current situation
   - Any follow-up needed
3. Tap **"Resolve"** to confirm
4. Alert turns green (resolved status)

#### Mark False Alarm
1. Tap **"False Alarm"** button
2. Confirm the action
3. Alert marked as false alarm
4. Helps track false alarm patterns

### Opening Location in Maps
- Tap the **blue location box** on any alert
- Google Maps opens with exact coordinates
- Use for navigation to emergency location

### Dashboard Features
- **Auto-refresh**: Alerts update in real-time
- **Manual refresh**: Tap refresh icon in app bar
- **Active count**: Shows number of active alerts
- **Filter options**: View by status (Active/Acknowledged/Resolved/All)

---

## System Behavior

### Online Mode
- ✅ Alert sent immediately to server
- ✅ Police portal receives notification
- ✅ All guards see alert in real-time
- ✅ Location tracked with GPS

### Offline Mode
- 📴 Alert saved locally on device
- 📴 Added to offline queue
- 📴 Location still captured (GPS works offline)
- 📴 Auto-syncs when connection restored
- 📴 Mesh propagation to nearby devices (future)

### Location Tracking
- 📍 Captures GPS coordinates (latitude/longitude)
- 📍 Reverse geocodes to readable address
- 📍 5-second timeout if GPS unavailable
- 📍 Works even without internet (cached maps)

---

## Workflow Example

### Scenario: Suspicious Person at Gate

**Resident (10:30 AM)**
1. Sees unknown person trying to enter gate
2. Opens app → Taps "SOS Alert"
3. Selects "Suspicious Person"
4. Types: "Unknown person at main gate, refuses to show ID"
5. Taps "SEND SOS ALERT"
6. Receives confirmation

**Guard (10:30 AM)**
1. Hears phone notification
2. Opens "SOS Alerts" dashboard
3. Sees red alert: "Suspicious Person - A-234"
4. Reads description
5. Taps location → Opens maps
6. Taps "Acknowledge" → On my way

**Guard (10:35 AM)**
1. Arrives at location
2. Checks person's ID
3. Determines visitor is legitimate
4. Escorts to flat A-234
5. Taps "Resolve"
6. Enters notes: "Visitor verified, ID checked, escorted to A-234"
7. Taps "Resolve" button
8. Alert closed

**Police Portal (Real-time)**
- Receives alert at 10:30 AM
- Sees location on map
- Monitors guard response
- Sees resolution at 10:35 AM
- No action needed (handled by guard)

---

## Permissions Required

### Android
```xml
<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS
```xml
<!-- Info.plist entries -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to send SOS alerts with your current position</string>
```

Users must grant these permissions when first using SOS feature.

---

## Troubleshooting

### "Location permission required for SOS"
- **Solution**: Go to device Settings → Apps → Society Safety → Permissions → Enable Location

### Alert not sending
- **Check**: Internet connection
- **Solution**: Alert will be queued and sent when online
- **Verify**: Look for orange "Queued" badge

### Can't see location on maps
- **Check**: GPS is enabled on device
- **Solution**: Enable GPS in device quick settings
- **Alternative**: Address will still be captured if available

### Guard not seeing alerts
- **Check**: Guard is logged in
- **Solution**: Refresh the dashboard (pull down or tap refresh icon)
- **Backend**: Ensure server is running and API connected

### False location shown
- **Reason**: GPS accuracy issues indoors
- **Solution**: Move near window for better GPS signal
- **Note**: Address is approximate based on GPS data

---

## Best Practices

### For Residents
- ✅ Use only for genuine emergencies
- ✅ Provide clear description
- ✅ Stay in safe location after sending alert
- ✅ Keep phone on and volume up
- ❌ Don't spam multiple alerts
- ❌ Don't use for non-emergencies

### For Guards
- ✅ Acknowledge alerts immediately
- ✅ Add detailed resolution notes
- ✅ Keep dashboard open during duty
- ✅ Enable notifications
- ❌ Don't mark as false alarm without verifying
- ❌ Don't delay acknowledgment

---

## Statistics & Metrics

Guards can track:
- Total alerts received
- Average response time
- Alerts by type
- False alarm rate
- Peak hours for emergencies

Residents can see:
- Their alert history
- Response times
- Resolution status

---

## Privacy & Security

- 🔒 Location shared only during active SOS
- 🔒 Data encrypted in transit
- 🔒 Audit trail maintained
- 🔒 Police access logged
- 🔒 Personal info protected

---

## Support

If you encounter issues:
1. Check internet connection
2. Verify location permission
3. Restart the app
4. Contact society security office
5. Report bugs to admin

---

## Future Features (Coming Soon)

- 📸 Photo capture during emergency
- 🔔 Push notifications to all guards
- 🌐 Mesh network for offline propagation
- ⛓️ Blockchain audit trail
- 📊 Advanced analytics dashboard
- 🚨 Integration with police CAD systems
- 🎯 Geo-fencing for automatic alerts

---

## Emergency Contacts

Keep these handy:
- **Society Security**: [Add number]
- **Police Control Room**: 100
- **Fire Department**: 101
- **Ambulance**: 102
- **Women Helpline**: 1091

---

## Summary

| Feature | Residents | Guards | Police |
|---------|-----------|---------|--------|
| Trigger SOS | ✅ | ❌ | ❌ |
| View Alerts | Own only | All | All |
| Acknowledge | ❌ | ✅ | ✅ |
| Resolve | ❌ | ✅ | ✅ |
| Location Access | Own | All alerts | All alerts |
| Real-time Updates | ❌ | ✅ | ✅ |
| Offline Queue | ✅ | ✅ | ❌ |

**Remember**: SOS is for emergencies only. Your safety is our priority! 🛡️
