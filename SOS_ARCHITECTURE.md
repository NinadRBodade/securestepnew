# 🏗️ SOS Alert Architecture & Implementation

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      SECURESTEP SOS SYSTEM                      │
└─────────────────────────────────────────────────────────────────┘

    FRONTEND LAYER
    ┌──────────────────────────────────────────────┐
    │  Mobile App (Flutter)      │  Web Portals    │
    │  - Resident SOS Screen     │  - Police       │
    │  - Emergency Selection     │  - Admin        │
    │  - Location Capture        │  - Guards       │
    │  - HTTP POST /api/sos      │  - Agent        │
    └──────────┬──────────────────────────────────┘
               │ REST API
               ▼
    BACKEND LAYER
    ┌──────────────────────────────────────────────┐
    │       Express.js API Server (Port 5001)      │
    │  - POST /api/sos          [Trigger SOS]      │
    │  - GET /api/sos           [Get All SOS]      │
    │  - PUT /api/sos/:id/...   [Update Status]    │
    └──────────┬──────────────────────────────────┘
               │
    ┌──────────┴──────────────────────────────────┐
    │                                              │
    ▼                                              ▼
DATABASE                                  SOCKET.IO (Real-time)
┌─────────────────────┐              ┌──────────────────────┐
│   MongoDB           │              │  Event Broadcast     │
│  - SOS Events       │              │  - To 'police' room  │
│  - Users            │              │  - To 'guards' room  │
│  - Societies        │              │  - To society rooms  │
│  - Guards           │              │                      │
│  - Agents           │              │  Event: police:sos.. │
└─────────────────────┘              └──────────────────────┘
                                              │
                                              ▼
                                    Web Portal (Port 8080)
                                    ┌──────────────────────┐
                                    │  Police Portal       │
                                    │  - Real-time alerts  │
                                    │  - Map display       │
                                    │  - Response tracking │
                                    │  - Statistics        │
                                    └──────────────────────┘
```

---

## Data Flow: Sending SOS Alert

### Step 1: Mobile App Initiates SOS
**Component:** `lib/screens/resident/emergency_sos_screen.dart`

```dart
// User selects emergency type and taps "SEND SOS ALERT"
final sosEvent = await _sosService.triggerSOS(
    societyId: widget.user.societyId,
    flatNumber: widget.user.flatNumber,
    description: "Fire: Test alert",
    userId: widget.user.email,
    userName: widget.user.name,
);
```

**What Happens:**
1. Gets current GPS location
2. Reverse geocodes to address
3. Prepares SOS data object
4. Reads JWT token from SharedPreferences

### Step 2: Service Layer
**Component:** `lib/services/sos_service.dart`

```dart
// Sends HTTP POST request with bearer token
final response = await _dio.post('/sos', 
    data: {
        'societyId': societyId,
        'flatNumber': flatNumber,
        'description': description,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationAddress': address,
    }
);

// Token is automatically added by interceptor:
options.headers['Authorization'] = 'Bearer $token';
```

### Step 3: Backend API Receives
**Component:** `backend/src/routes/sos.routes.js`

```javascript
// Route definition
router.post(
    '/',
    sosLimiter,                        // Rate limiting
    authorize('resident', 'guard'),    // Authentication
    sosController.triggerSOS           // Handler
);
```

### Step 4: SOS Controller Processes
**Component:** `backend/src/controllers/sos.controller.js`

```javascript
exports.triggerSOS = async (req, res) => {
    // 1. Extract data from request
    const { societyId, flatNumber, latitude, longitude, description } = req.body;
    const user = req.user;  // From auth middleware
    
    // 2. Generate unique SOS ID
    const sosId = `SOS${Date.now()}${Math.floor(Math.random() * 10000)}`;
    
    // 3. Create SOS event object
    const sosEvent = {
        sosId,
        triggeredBy: { userId: user.id, name: user.name, ... },
        societyId,
        flatNumber,
        location: { latitude, longitude, address: ... },
        status: 'triggered',
        description,
        triggeredAt: new Date(),
    };
    
    // 4. Generate blockchain hash for integrity
    const blockchainHash = blockchainService.generateHash(sosDataForHash);
    
    // 5. Save to MongoDB (PERSISTENT STORAGE)
    const savedSOS = await SOSEvent.create({
        sosId,
        userId: user.id,
        userName: user.name,
        societyId,
        flatNumber,
        latitude,
        longitude,
        locationAddress,
        status: 'active',
        description,
        blockchainHash,
    });
    
    // 6. Add to in-memory cache
    sosEvent.blockchainHash = blockchainHash;
    sosEvents.push(sosEvent);
    
    // 7. Emit via Socket.IO (REAL-TIME BROADCAST)
    socketService.emitSOSAlert(sosEvent);
    
    // 8. Return success response
    res.status(201).json({
        status: 'success',
        data: { sosEvent: sanitized }
    });
};
```

### Step 5: Socket.IO Broadcast
**Component:** `backend/src/services/socket.service.js`

```javascript
emitSOSAlert(sosEvent) {
    // Sanitize sensitive data
    const sanitizedEvent = { ...sosEvent };
    delete sanitizedEvent.blockchainHash;
    
    // 1. Emit to police room
    io.to('police').emit('police:sos-alert', sanitizedEvent);
    
    // 2. Emit to guards room
    io.to('guards').emit('sos:new', sanitizedEvent);
    
    // 3. Emit to specific society
    if (sosEvent.societyId) {
        io.to(sosEvent.societyId).emit('sos:new', sanitizedEvent);
    }
}
```

### Step 6: Police Portal Receives
**Component:** `police_portal/script.js`

```javascript
// Socket.IO initialized on page load
socket = io(CONFIG.SOCKET_URL);  // Auto-determines backend URL

// Listen for police alerts
socket.on('police:sos-alert', (data) => {
    console.log('🚨 NEW SOS ALERT:', data);
    
    // Format alert
    const alert = {
        sosId: data.sosId,
        triggeredBy: data.triggeredBy,
        flatNumber: data.flatNumber,
        description: data.description,
        location: data.location,
        // ... other fields
    };
    
    // Add to UI
    addNewAlert(alert);
    
    // Play sound & notification
    playAlertSound();
    showNotification('New Alert', `${data.triggeredBy.name} - ${data.flatNumber}`);
    
    // Update map & stats
    updateMap();
    updateStats();
});
```

---

## Key Components

### 1. SOS Model
**File:** `backend/src/models/SOSEvent.js`

```javascript
{
    sosId: String,                    // Unique alert ID
    userId: String,                   // Who triggered
    userName: String,
    userRole: String,
    societyId: String,                // NEW: Which society
    flatNumber: String,               // Location in building
    
    // Location data
    latitude: String,
    longitude: String,
    locationAddress: String,
    
    // Status workflow
    status: ['active', 'acknowledged', 'resolved', 'triggered', 'arrived'],
    
    // Response tracking
    guardId: String,
    guardArrivedAt: Date,
    acknowledgedAt: Date,
    resolvedAt: Date,
    
    // Data integrity
    blockchainHash: String,
    
    // Timestamps
    triggeredAt: Date,
    createdAt: Date,
    updatedAt: Date
}
```

### 2. Socket.IO Rooms
**Location:** `backend/src/config/socket.js`

```javascript
// Connection flow:
socket.on('connection', (socket) => {
    // 1. Police portal auto-joins
    socket.join('police');
    console.log('Socket joined police room');
    
    // 2. Guards join when they come online
    socket.on('guard:online', () => {
        socket.join('guards');
    });
    
    // 3. Residents can join society rooms
    socket.on('society:join', (societyId) => {
        socket.join(societyId);
    });
});

// When SOS emitted:
// io.to('police').emit(...)        → All police portals
// io.to('guards').emit(...)        → All online guards
// io.to(societyId).emit(...)       → All residents in society
```

### 3. URL Resolution (THE FIX!)
**Location:** `police_portal/script.js` (Lines 1-20)

```javascript
// BEFORE: Hardcoded
// API_BASE_URL: 'http://192.168.1.59:5001/api'

// AFTER: Dynamic detection
const getBackendURL = () => {
    const hostname = window.location.hostname;
    const protocol = window.location.protocol;
    
    if (hostname === 'localhost' || hostname === '127.0.0.1') {
        return `${protocol}//localhost:5001`;
    }
    return `${protocol}//${hostname}:5001`;
};

const CONFIG = {
    API_BASE_URL: `${getBackendURL()}/api`,
    SOCKET_URL: getBackendURL(),
};
```

**Why This Works:**
- If accessing from `localhost:8080` → connects to `localhost:5001`
- If accessing from `192.168.1.59:8080` → connects to `192.168.1.59:5001`
- Maintains the `protocol` (http/https)
- Always uses port `5001` for backend

---

## API Endpoints

### Public Endpoints (No Auth)
```
GET  /api/sos/police/dashboard      → Get all SOS for police
GET  /api/sos/:sosId/verify         → Verify SOS integrity
```

### Protected Endpoints (Auth Required)
```
POST   /api/sos                      → Trigger SOS
GET    /api/sos                      → Get all SOS (with filters)
GET    /api/sos/:sosId               → Get specific SOS
PUT    /api/sos/:sosId/acknowledge   → Guard acknowledges
PUT    /api/sos/:sosId/arrived       → Guard arrived
PUT    /api/sos/:sosId/resolve       → Resolve SOS
```

---

## Status Workflow

```
triggered ──[Guard Responds]──> acknowledged ──[Resolved]──> resolved
    │                                  │
    │                                  └─[Still Active]
    │
    └─[False Alarm]──> false_alarm


Status Lifecycle:
1. "triggered" → Alert just sent (1-5 seconds)
2. "acknowledged" → Guard confirmed viewing (1-10 minutes)
3. "arrived" → Guard or official at location (5-60 minutes)
4. "resolved" → Emergency handled (final state)
5. "false_alarm" → Not a real emergency (final state)
```

---

## Error Handling

### Validation
- EmergencyType must be valid (6 types)
- FlatNumber required
- SocietyId required
- Location must be provided or permission denied

### Limits
- Rate limiting: 5 SOS per minute per user (burst allowed)
- Prevents spam/abuse

### Error Response
```javascript
{
    status: 'error',
    message: 'Failed to trigger SOS',
    error: 'Location permission denied'
}
```

---

## Performance Considerations

1. **Database Indexing**
   - `sosId` (unique): Fast lookup by ID
   - `userId` (index): Filter by user
   - `status` + `createdAt` (index): Filter by status
   - `societyId` (index): Filter by society

2. **In-Memory Cache**
   - Last 100 SOS events in memory
   - Fast initial load without DB query
   - Synced with MongoDB for persistence

3. **Socket.IO Optimization**
   - Sanitizes sensitive data before broadcast
   - Removes blockchain hash from client responses
   - Uses room-based broadcasting (not global)

4. **Location Processing**
   - Async geocoding (doesn't block SOS sending)
   - 5-second timeout prevents hanging
   - Falls back to coordinates if geocoding fails

---

## Security Features

1. **Authentication**
   - JWT token required for SOS trigger
   - Token verified by `protect` middleware

2. **Authorization**
   - Only residents/guards can trigger
   - Police access is read-only (public endpoint)

3. **Rate Limiting**
   - Prevents SOS spam
   - 5 alerts per minute limit

4. **Data Integrity**
   - Blockchain hash generated for each SOS
   - Detects tampering via `GET /:sosId/verify`

5. **CORS Enabled**
   - Allows mobile app to reach API
   - Allows cross-origin Socket.IO connections

---

## Future Enhancements

1. **Real-time Location Tracking**
   - Live guard location updates
   - Route optimization for response

2. **SMS/Email Notifications**
   - SMS to family
   - Email to registered contacts

3. **Multi-language Support**
   - Alert messages in multiple languages
   - Regional emergency numbers

4. **Advanced Analytics**
   - Response time metrics
   - Hotspot analysis
   - Trend detection

5. **Integration with Emergency Services**
   - Direct dispatch to 911/999/112
   - Emergency service app integration
   - Automated call initiation

---

**Architecture Version:** 1.0  
**Last Updated:** 2024-04-19  
**Status:** Production Ready ✅
