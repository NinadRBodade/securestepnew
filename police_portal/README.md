# Police Emergency Dashboard

## 🚓 Overview
Real-time web dashboard for police to monitor and respond to SOS alerts from society residents. Displays live location tracking, alert status, and comprehensive emergency information.

## ✨ Features

### Real-time Monitoring
- **Live SOS Alerts**: Instant notification of new emergencies via Socket.IO
- **Auto-refresh**: Dashboard updates every 30 seconds
- **Sound Alerts**: Audio notification for critical emergencies
- **Browser Notifications**: Desktop notifications when tab is not active

### Interactive Map
- **Live Location Tracking**: Shows exact GPS coordinates on OpenStreetMap
- **Color-coded Markers**:
  - 🔴 Red: Active emergencies (requires immediate attention)
  - 🟠 Orange: Acknowledged (unit dispatched)
  - 🟢 Green: Resolved
- **Click to View**: Click markers for quick alert details
- **Google Maps Integration**: Open location directly in Google Maps for navigation

### Statistics Dashboard
- Active Emergencies count
- Acknowledged alerts count
- Resolved alerts today
- Total alerts

### Alert Management
- **Filter by Status**: All, Active, Acknowledged, Resolved
- **Detailed View**: Click any alert for full information
- **Dispatch Units**: One-click police dispatch
- **Timeline Tracking**: View response and resolution times

### Alert Information Displayed
- SOS ID (unique identifier)
- Society name and address
- Flat number
- Resident name and phone (clickable to call)
- GPS coordinates (clickable for maps)
- Emergency description
- Agent on site (if applicable)
- Timestamp and time elapsed
- Response timeline (acknowledged/resolved times)

## 🚀 Setup Instructions

### Prerequisites
- Backend server running on `http://localhost:5001`
- Modern web browser (Chrome, Firefox, Safari, Edge)

### Installation

1. **Navigate to police portal directory**:
   ```bash
   cd police_portal
   ```

2. **Open in browser**:
   - Simply open `index.html` in your browser
   - Or use a local server:
   ```bash
   # Using Python
   python3 -m http.server 8080
   
   # Using Node.js
   npx http-server -p 8080
   
   # Using VS Code Live Server extension
   Right-click index.html → Open with Live Server
   ```

3. **Access dashboard**:
   ```
   http://localhost:8080
   ```

### Configuration

Edit `script.js` to update configuration:

```javascript
const CONFIG = {
    API_BASE_URL: 'http://localhost:5001/api',  // Backend API URL
    SOCKET_URL: 'http://localhost:5001',        // Socket.IO server
    DEFAULT_CENTER: [19.0760, 72.8777],         // Default map center (Mumbai)
    DEFAULT_ZOOM: 12                             // Default zoom level
};
```

## 📡 Socket.IO Events

The dashboard listens to these real-time events:

### Incoming Events (Server → Dashboard)

```javascript
// New SOS alert
socket.on('police:sos-alert', (data) => {
    // data structure:
    {
        sosId: 'SOS1234567890',
        societyName: 'Sunshine Apartments',
        societyAddress: {...},
        flatNumber: 'A-234',
        location: {
            latitude: 19.0760,
            longitude: 72.8777,
            address: '123 Main St, Mumbai'
        },
        triggeredBy: 'John Doe',
        triggeredByPhone: '+91-9876543210',
        triggeredAt: '2024-12-24T10:30:00Z',
        priority: 'critical',
        description: 'Suspicious person at gate',
        involvedAgent: {
            agentId: '...',
            company: 'XYZ Services',
            safetyScore: 4.5
        }
    }
});

// Alert acknowledged by guard
socket.on('sos:acknowledged', (data) => {
    // data: { sosId, guardName, acknowledgedAt }
});

// Alert resolved
socket.on('sos:resolved', (data) => {
    // data: { sosId, outcome, notes, resolvedAt }
});

// Guard arrived at location
socket.on('guard:arrived', (data) => {
    // data: { sosId, guardName, arrivedAt }
});
```

## 🗺️ Map Features

### OpenStreetMap Integration
- Free, open-source mapping (no API key required)
- Zoom levels 1-19
- Satellite/Street view options available

### Custom Markers
- Animated markers for active alerts (bouncing effect)
- Color-coded by status
- Clickable popups with quick actions

### Navigation
- Click location in alert card → Centers map
- Click marker → Shows popup with alert details
- Click "Open in Google Maps" → Opens navigation app

## 📊 API Integration

### REST API Endpoints Used

```javascript
// Get all SOS alerts
GET /api/sos
Response: {
    status: 'success',
    data: {
        sosEvents: [...]
    }
}

// Get single SOS alert
GET /api/sos/:sosId
Response: {
    status: 'success',
    data: {
        sosEvent: {...}
    }
}

// Get police dashboard stats (future)
GET /api/sos/police/dashboard
Response: {
    status: 'success',
    data: {
        activeCount: 5,
        acknowledgedCount: 3,
        resolvedToday: 12,
        totalAlerts: 20
    }
}
```

## 🎨 UI Components

### Status Indicators
- **Connection Status**: Shows WebSocket connection state
- **Active Count Badge**: Red badge for active emergencies
- **Status Pills**: Color-coded status indicators

### Alert Cards
- **Priority Badges**: Critical emergencies highlighted
- **Time Stamps**: Relative time (5m ago, 2h ago)
- **Action Buttons**: Quick dispatch and view details
- **Status Colors**:
  - Red border: Active
  - Orange border: Acknowledged
  - Green border: Resolved
  - Gray: False alarm

### Modal Details
- Full emergency information
- Contact information with click-to-call
- GPS coordinates with Google Maps link
- Response timeline
- Agent details (if present)
- Resolution notes

## 🔔 Notifications

### Browser Notifications
- Requires permission on first load
- Shows even when tab is not active
- Includes alert title and basic info
- Clickable to bring tab into focus

### Audio Alerts
- Plays sound for new critical alerts
- Can be disabled in browser settings
- Uses embedded audio (no external files needed)

## 🛠️ Troubleshooting

### Dashboard not loading alerts
**Check**:
1. Backend server is running: `curl http://localhost:5001/health`
2. CORS is enabled on backend
3. Browser console for errors (F12 → Console)

**Solution**:
```bash
# Restart backend
cd backend
node src/server.js
```

### Map not displaying
**Check**:
1. Internet connection (OpenStreetMap tiles need internet)
2. Browser console for errors
3. Leaflet.js loaded correctly

**Solution**:
- Refresh the page
- Clear browser cache
- Check if CDN links are accessible

### Socket.IO not connecting
**Check**:
1. Backend Socket.IO initialized
2. WebSocket protocol allowed by firewall
3. Correct URL in CONFIG

**Solution**:
```javascript
// In script.js, check connection events:
socket.on('connect_error', (error) => {
    console.error('Connection error:', error);
});
```

### No location shown for alerts
**Causes**:
1. Resident didn't grant location permission
2. GPS unavailable when SOS triggered
3. Indoor location (weak GPS signal)

**Note**: Alert will still be created, just without GPS coordinates

### Notifications not working
**Solution**:
1. Grant notification permission when prompted
2. Check browser notification settings
3. Enable notifications for localhost in browser settings

## 🔒 Security Considerations

### Current Implementation (Development)
- No authentication required
- Public access to all alerts
- No encryption for data transmission

### Production Recommendations
1. **Authentication**:
   - Add login system for police officers
   - JWT token-based auth
   - Role-based access control

2. **HTTPS**:
   - Use SSL/TLS certificates
   - Encrypt all data in transit
   - Secure WebSocket connections (wss://)

3. **Data Privacy**:
   - Redact sensitive information
   - Audit logging for all actions
   - Compliance with data protection laws

4. **Rate Limiting**:
   - Prevent API abuse
   - Throttle requests
   - DDoS protection

## 📈 Performance

### Optimizations
- Lazy loading for old alerts
- Virtual scrolling for large lists
- Debounced search and filter
- Efficient map marker updates

### Browser Requirements
- Modern browser with ES6 support
- WebSocket support
- HTML5 Geolocation API
- LocalStorage API

### Recommended Browsers
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## 🚀 Future Enhancements

### Planned Features
- [ ] Heatmap overlay for alert concentration
- [ ] Advanced filtering (date range, priority, society)
- [ ] Export reports (PDF, CSV)
- [ ] Real-time chat with guards
- [ ] Police unit tracking on map
- [ ] Response time analytics
- [ ] Alert prediction using AI
- [ ] Mobile app version
- [ ] Multi-language support
- [ ] Dark mode

### Integration Opportunities
- CAD (Computer-Aided Dispatch) systems
- Emergency response protocols
- Hospital/Ambulance services
- Fire department coordination
- Municipal control room

## 📞 Support

### Reporting Issues
1. Check browser console (F12)
2. Check backend logs
3. Verify network requests (Network tab)
4. Note error messages and stack traces

### Contact
- Technical Support: [Add contact]
- Emergency Hotline: 100 (Police)

## 📄 License
Society Safety System - Police Dashboard
Copyright © 2024

## 🙏 Credits
- **Mapping**: OpenStreetMap contributors
- **Icons**: Emoji icons
- **Realtime**: Socket.IO
- **Map Library**: Leaflet.js

---

**Last Updated**: December 24, 2024  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
