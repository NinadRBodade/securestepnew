# Backend Architecture Summary

## 🏗️ Overview
The Society Safety Backend is a Node.js/Express server providing REST APIs for a comprehensive society management and safety system. It handles authentication, agent verification, SOS alerts, visitor management, and real-time communication via Socket.IO.

**Version:** 1.0.0  
**Base URL:** `http://localhost:5001`  
**Database:** MongoDB Atlas (Cloud)  
**Real-time:** Socket.IO 4.7.5

---

## 📚 Technology Stack

### Core Dependencies
```json
{
  "express": "^4.19.2",          // Web framework
  "mongoose": "^8.5.1",          // MongoDB ODM
  "socket.io": "^4.7.5",         // Real-time communication
  "jsonwebtoken": "^9.0.2",      // JWT authentication
  "bcryptjs": "^2.4.3",          // Password hashing
  "multer": "^1.4.5-lts.1",      // File upload middleware
  "qrcode": "^1.5.4",            // QR code generation
  "cors": "^2.8.5",              // Cross-origin requests
  "dotenv": "^16.4.5",           // Environment variables
  "joi": "^17.13.3",             // Data validation
  "uuid": "^13.0.0",             // Unique IDs
  "winston": "^3.13.0",          // Logging
  "ethers": "^6.13.2"            // Blockchain integration
}
```

### Runtime Requirements
- **Node.js:** >= 18.0.0
- **MongoDB:** Cloud Atlas cluster
- **Port:** 5001 (configurable via .env)

---

## 🗂️ Project Structure

```
backend/
├── src/
│   ├── server.js              # Main entry point
│   ├── config/
│   │   ├── database.js        # MongoDB connection
│   │   ├── socket.js          # Socket.IO configuration
│   │   └── multer.config.js   # File upload settings
│   ├── routes/
│   │   ├── auth.routes.js     # Authentication endpoints
│   │   ├── agent.routes.js    # Agent verification & QR
│   │   ├── resident.routes.js # Resident management
│   │   ├── guard.routes.js    # Guard operations
│   │   ├── admin.routes.js    # Admin panel
│   │   ├── sos.routes.js      # SOS alerts
│   │   ├── visit.routes.js    # Visitor tracking
│   │   ├── society.routes.js  # Society info
│   │   ├── face.routes.js     # Face recognition
│   │   └── blockchain.routes.js # Blockchain audit
│   ├── controllers/           # Business logic
│   ├── models/
│   │   ├── User.js            # Base user model
│   │   ├── Agent.js           # Agent verification data
│   │   ├── Resident.js        # Resident profiles
│   │   ├── Guard.js           # Guard assignments
│   │   ├── Admin.js           # Admin privileges
│   │   ├── SOSEvent.js        # Emergency alerts
│   │   ├── Visit.js           # Visitor logs
│   │   ├── Society.js         # Society details
│   │   └── Complaint.js       # Issue tracking
│   ├── services/
│   │   ├── qr.service.js      # QR generation
│   │   ├── socket.service.js  # Real-time events
│   │   ├── notification.service.js # Push notifications
│   │   ├── sync.service.js    # Offline sync
│   │   └── blockchain.service.js # Blockchain integration
│   ├── middleware/
│   │   └── error.middleware.js # Global error handler
│   └── utils/                 # Helper functions
├── uploads/
│   ├── agents/                # Agent documents
│   └── faces/                 # Face recognition images
├── .env                       # Environment variables
├── package.json
└── README.md
```

---

## 🔐 Authentication & Authorization

### JWT-Based Authentication
- **Token Type:** Bearer tokens
- **Expiry:** Configurable (default: 7 days)
- **Secret:** Stored in `.env` as `JWT_SECRET`

### User Roles
1. **Resident** - Society members, can trigger SOS, scan agents
2. **Agent** - Service providers (plumbers, electricians, delivery)
3. **Guard** - Security personnel, respond to SOS alerts
4. **Admin** - Society management, approve/reject agents

### Password Security
- Hashed using bcryptjs (10 salt rounds)
- Never stored or transmitted in plain text
- Secure password reset (future feature)

---

## 📡 API Endpoints

### 🔑 Authentication (`/api/auth`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/register` | Create new user account | ❌ |
| POST | `/login` | Login and get JWT token | ❌ |
| GET | `/health` | Health check | ❌ |
| GET | `/users` | Get all users (dev only) | ❌ |

**Example Request:**
```bash
POST /api/auth/login
{
  "email": "resident@gmail.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "67890",
    "email": "resident@gmail.com",
    "role": "resident",
    "name": "John Doe"
  }
}
```

---

### 👨‍🔧 Agent Management (`/api/agent`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/register` | Submit agent verification documents | ✅ |
| GET | `/verification/pending` | List pending agents (admin) | ✅ |
| POST | `/verification/approve/:agentId` | Approve agent & generate QR | ✅ Admin |
| POST | `/verification/reject/:agentId` | Reject agent application | ✅ Admin |
| PUT | `/:agentId/score` | Update trust score | ✅ |
| GET | `/scan/:qrData` | Decode QR and get agent info | ✅ |
| GET | `/:agentId` | Get agent details by ID | ✅ |
| GET | `/` | List all agents | ✅ |

**Document Upload Fields:**
- `idProof` - Government ID (PDF/Image, max 5MB)
- `photo` - Agent photo (JPEG/PNG)
- `certificate` - Trade license/certification

**Agent Verification Flow:**
1. Agent registers with documents → `POST /register`
2. Admin reviews → `GET /verification/pending`
3. Admin approves → `POST /verification/approve/:id` → QR code generated
4. Agent receives QR code in response
5. Resident scans QR → `GET /scan/:qrData` → Shows agent details

**Trust Score System:**
- Range: 0.0 to 5.0
- Based on: Completion rate, feedback, punctuality
- Updated via: `PUT /:agentId/score`

---

### 🏠 Resident Management (`/api/residents`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | List all residents | ✅ |

*More endpoints coming soon*

---

### 🛡️ Guard Operations (`/api/guards`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | List all guards | ✅ |

*More endpoints coming soon*

---

### 🚨 SOS Alerts (`/api/sos`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/alerts` | Get all SOS alerts | ✅ |
| POST | `/alert` | Create new SOS alert | ✅ Resident |

**SOS Alert Schema:**
```json
{
  "residentId": "user_id",
  "residentName": "John Doe",
  "flatNumber": "A-234",
  "emergencyType": "Suspicious Person",
  "description": "Unknown person at gate",
  "location": {
    "latitude": 19.0760,
    "longitude": 72.8777,
    "address": "123 Main St, Mumbai"
  },
  "status": "active",  // active, acknowledged, resolved, false_alarm
  "timestamp": "2024-12-24T10:30:00Z",
  "acknowledgedBy": "guard_id",
  "acknowledgedAt": "2024-12-24T10:31:00Z",
  "resolvedBy": "guard_id",
  "resolvedAt": "2024-12-24T10:45:00Z",
  "resolutionNotes": "Situation handled"
}
```

**Emergency Types:**
- Suspicious Person
- Medical Emergency
- Fire
- Theft
- Violence
- Other

**Real-time Updates:**
- Guards receive instant notifications via Socket.IO
- Police portal receives alerts
- Status changes broadcast to all connected clients

---

### 🎭 Face Recognition (`/api/face`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/upload` | Upload agent face image | ✅ |
| GET | `/image/:email` | Download face image | ✅ |
| GET | `/check/:email` | Check if face registered | ✅ |
| DELETE | `/delete/:email` | Remove face registration | ✅ |

**Upload Format:**
- Multipart form data
- Field: `faceImage` (JPEG/PNG, max 5MB)
- Additional fields: `email`, `role`

**Storage:**
- Path: `uploads/faces/`
- Naming: `{sanitized_email}_{timestamp}.jpg`
- Current: In-memory Map (dev mode)
- Production: Migrate to MongoDB

**Usage Flow:**
1. Agent registers face → `POST /upload`
2. Backend stores image and metadata
3. Resident verifies agent → `GET /image/:email`
4. App downloads image and compares with live camera
5. Match score calculated locally (ML Kit)

---

### 🏢 Society Management (`/api/societies`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Get society information | ✅ |

---

### 👥 Visitor Tracking (`/api/visits`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Get visitor logs | ✅ |

---

### ⛓️ Blockchain Integration (`/api/blockchain`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Get blockchain status | ✅ |

*Future: Immutable audit trail for critical events*

---

### 👨‍💼 Admin Panel (`/api/admin`)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Admin dashboard data | ✅ Admin |

---

## 🗄️ Database Models

### User (Base Model)
```javascript
{
  email: String (unique, required),
  password: String (hashed, required),
  role: String (resident/agent/guard/admin),
  name: String,
  phone: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Agent
```javascript
{
  userId: ObjectId (ref: User),
  email: String,
  name: String,
  phone: String,
  documents: {
    idProof: String (file path),
    photo: String (file path),
    certificate: String (file path)
  },
  verificationStatus: String (pending/approved/rejected),
  verifiedBy: ObjectId (ref: Admin),
  verifiedAt: Date,
  rejectionReason: String,
  qrCode: String (base64 image),
  qrId: String (unique),
  score: Number (0-5),
  totalJobs: Number,
  completedJobs: Number,
  rating: Number
}
```

### SOSEvent
```javascript
{
  residentId: ObjectId (ref: User),
  residentName: String,
  flatNumber: String,
  emergencyType: String,
  description: String,
  location: {
    latitude: Number,
    longitude: Number,
    address: String
  },
  status: String (active/acknowledged/resolved/false_alarm),
  timestamp: Date,
  acknowledgedBy: ObjectId (ref: Guard),
  acknowledgedAt: Date,
  resolvedBy: ObjectId (ref: Guard),
  resolvedAt: Date,
  resolutionNotes: String,
  offlineQueued: Boolean
}
```

### Visit
```javascript
{
  visitorName: String,
  visitorPhone: String,
  flatNumber: String,
  residentId: ObjectId (ref: Resident),
  purpose: String,
  entryTime: Date,
  exitTime: Date,
  guardId: ObjectId (ref: Guard),
  status: String (entered/exited),
  vehicleNumber: String,
  photo: String (file path)
}
```

### Resident
```javascript
{
  userId: ObjectId (ref: User),
  flatNumber: String,
  buildingName: String,
  ownerName: String,
  memberCount: Number,
  vehicleNumbers: [String],
  emergencyContact: String
}
```

### Guard
```javascript
{
  userId: ObjectId (ref: User),
  shiftTiming: String,
  assignedGates: [String],
  badgeNumber: String,
  joiningDate: Date,
  status: String (active/inactive)
}
```

---

## 🔄 Real-time Features (Socket.IO)

### Event Types
```javascript
// Server → Client
'sos:alert' - New SOS alert created
'sos:acknowledged' - Alert acknowledged by guard
'sos:resolved' - Alert resolved
'agent:approved' - Agent verification approved
'visit:entry' - New visitor entered
'visit:exit' - Visitor exited

// Client → Server
'guard:online' - Guard connected
'guard:offline' - Guard disconnected
'location:update' - Guard location update
```

### Connection
```javascript
const socket = io('http://localhost:5001');

socket.on('connect', () => {
  console.log('Connected to server');
});

socket.on('sos:alert', (data) => {
  // Show notification to guards
  console.log('New SOS Alert:', data);
});
```

---

## 📁 File Upload System

### Multer Configuration
- **Storage:** Disk storage
- **Destination:** `uploads/agents/` or `uploads/faces/`
- **Filename:** `{fieldname}_{timestamp}_{random}.ext`
- **Size Limit:** 5MB per file
- **Allowed Types:**
  - Images: `image/jpeg`, `image/jpg`, `image/png`
  - Documents: `application/pdf`

### Validation
```javascript
fileFilter: (req, file, cb) => {
  const allowedMimeTypes = /image\/(jpeg|jpg|png)|application\/pdf/;
  const mimetype = allowedMimeTypes.test(file.mimetype);
  
  if (mimetype) {
    cb(null, true);
  } else {
    cb(new Error('Only images and PDFs allowed'));
  }
}
```

---

## 🔒 Security Features

### Implemented
✅ **JWT Authentication** - Secure token-based auth  
✅ **Password Hashing** - bcryptjs with 10 salt rounds  
✅ **CORS Enabled** - Cross-origin resource sharing  
✅ **File Validation** - MIME type and size checks  
✅ **Error Middleware** - Global error handling  
✅ **Environment Variables** - Sensitive data in .env  

### Recommended for Production
🔐 **Rate Limiting** - Prevent brute force attacks  
🔐 **Helmet.js** - Security headers  
🔐 **Input Sanitization** - Prevent injection attacks  
🔐 **HTTPS Only** - Encrypted communication  
🔐 **File Encryption** - Encrypt uploaded documents  
🔐 **Audit Logging** - Track all critical actions  
🔐 **Role-based Access Control** - Granular permissions  

---

## ⚙️ Environment Configuration

### `.env` File
```bash
NODE_ENV=development
PORT=5001

# MongoDB Atlas
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/society_safety?retryWrites=true&w=majority

# JWT Secret (Change in production!)
JWT_SECRET=society_safety_jwt_secret_key_change_in_production_2024

# Blockchain (Optional)
BLOCKCHAIN_PROVIDER_URL=https://rpc-mumbai.maticvigil.com
PRIVATE_KEY=
CONTRACT_ADDRESS=
```

---

## 🚀 Deployment

### Starting the Server
```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start

# Using environment variables
PORT=5001 node src/server.js
```

### Health Check
```bash
curl http://localhost:5001/health

Response:
{
  "status": "OK",
  "message": "Backend running"
}
```

### Expected Console Output
```
1. Loading dotenv...
2. Loading express...
3. Loading database config...
4. Loading socket config...
5. Loading routes...
🚀 Starting Society Safety Backend...
🔄 Connecting to MongoDB...
Socket.IO service initialized
🚀 Server running on port 5001
✅ MongoDB connected successfully
```

---

## 📊 Key Services

### QR Code Service (`qr.service.js`)
```javascript
generateAgentQR(agentData) // Returns QR code as base64 data URL
generateAgentQRBuffer(agentData) // Returns buffer for file export
decodeQRData(qrDataString) // Parses QR JSON payload
```

**QR Payload Structure:**
```json
{
  "id": "unique_qr_id",
  "agentId": "agent_database_id",
  "type": "agent",
  "timestamp": "2024-12-24T10:00:00Z"
}
```

### Socket Service (`socket.service.js`)
- Manages real-time connections
- Broadcasts SOS alerts to all guards
- Handles guard online/offline status
- Room-based messaging for societies

### Notification Service (`notification.service.js`)
- Push notifications (future)
- SMS alerts (future)
- Email notifications (future)

### Sync Service (`sync.service.js`)
- Handles offline queue processing
- Syncs data when connection restored
- Mesh network propagation (future)

### Blockchain Service (`blockchain.service.js`)
- Immutable audit trail
- Smart contract integration
- Event verification (future feature)

---

## 🐛 Error Handling

### Global Error Middleware
```javascript
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err : {}
  });
});
```

### Standard Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": { /* Details in dev mode only */ }
}
```

---

## 📈 Future Enhancements

1. **Database Optimization**
   - Add indexes for faster queries
   - Implement caching (Redis)
   - Archive old records

2. **Security Hardening**
   - Add rate limiting (express-rate-limit)
   - Implement Helmet.js
   - Add request validation middleware

3. **Face Recognition**
   - Migrate face data to MongoDB
   - Add face embeddings storage
   - Implement liveness detection

4. **Notifications**
   - Push notifications (FCM)
   - SMS alerts (Twilio)
   - Email notifications

5. **Analytics**
   - Response time tracking
   - Alert statistics
   - Agent performance metrics

6. **Blockchain Integration**
   - Complete smart contract deployment
   - Immutable audit trail
   - Decentralized verification

7. **Scalability**
   - Load balancing
   - Microservices architecture
   - Docker containerization

---

## 🧪 Testing

### Manual API Testing
```bash
# Login
curl -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@gmail.com","password":"password123"}'

# Get SOS alerts (with auth token)
curl -X GET http://localhost:5001/api/sos/alerts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Check face registration
curl http://localhost:5001/api/face/check/agent@gmail.com
```

### Testing Checklist
- [ ] User registration and login
- [ ] JWT token generation and validation
- [ ] Agent document upload (PDF, images)
- [ ] Admin approval/rejection flow
- [ ] QR code generation after approval
- [ ] QR scanning and data retrieval
- [ ] SOS alert creation
- [ ] Real-time Socket.IO events
- [ ] Face image upload/download
- [ ] File upload validation
- [ ] Error handling for invalid requests

---

## 📞 API Response Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | Success | Data retrieved successfully |
| 201 | Created | User registered successfully |
| 400 | Bad Request | Invalid email format |
| 401 | Unauthorized | Invalid or missing JWT token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Agent not found |
| 409 | Conflict | Email already exists |
| 500 | Server Error | Database connection failed |

---

## 🔧 Troubleshooting

### MongoDB Connection Failed
**Error:** `MongooseError: Could not connect to MongoDB`  
**Solution:**
- Check MONGODB_URI in .env
- Verify network allows MongoDB Atlas
- Check MongoDB Atlas IP whitelist

### Port Already in Use
**Error:** `EADDRINUSE: address already in use :::5001`  
**Solution:**
```bash
lsof -i:5001  # Find process
kill -9 PID   # Kill process
```

### File Upload Fails
**Error:** `Only images and PDFs allowed`  
**Solution:**
- Check file MIME type
- Ensure file size < 5MB
- Verify file extension matches content

### QR Code Generation Error
**Error:** `qrService.generateAgentQR is not a function`  
**Solution:**
- Restart server to reload modules
- Check qr.service.js exports
- Verify qrcode package is installed

---

## 📝 Summary

**Backend Status:** ✅ Fully Operational

**Key Capabilities:**
- ✅ Multi-role authentication (Resident, Agent, Guard, Admin)
- ✅ Agent verification with document upload
- ✅ QR code generation for verified agents
- ✅ Real-time SOS alerts with Socket.IO
- ✅ Face recognition backend storage
- ✅ File upload with validation
- ✅ MongoDB persistence
- ✅ JWT-based security

**Production Ready:**
- 🔶 Core features: YES
- 🔶 Security hardening: PARTIAL (needs rate limiting, helmet)
- 🔶 Scalability: BASIC (single instance, needs load balancing)
- 🔶 Monitoring: NO (needs logging, analytics)

**Next Priority:**
1. Add comprehensive logging (Winston)
2. Implement rate limiting
3. Add input validation middleware
4. Migrate face data to MongoDB
5. Set up automated tests
6. Deploy to production server

---

**Last Updated:** December 24, 2024  
**Backend Version:** 1.0.0  
**Server Status:** Running on port 5001 ✅
