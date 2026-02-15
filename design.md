# SecureStep - System Design Document

## 1. Document Overview

**Project**: SecureStep - Society Safety System  
**Document Type**: Technical Design Document  
**Version**: 1.0.0  
**Date**: February 14, 2026  
**Author**: Development Team

This document describes the architecture, design patterns, technology stack, and implementation details of the SecureStep system.

---

## 2. Architecture Overview

### 2.1 High-Level System Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER (Presentation)                 │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │  Flutter App     │  │  Admin Portal    │  │ Police Portal│  │
│  │  (Mobile)        │  │  (Web)           │  │  (Web)       │  │
│  └────────┬─────────┘  └────────┬─────────┘  └──────┬───────┘  │
│           │                     │                    │          │
└───────────┼─────────────────────┼────────────────────┼──────────┘
            │                     │                    │
            │                  HTTP/REST            WebSocket
            │         (REST API)   │               (Socket.IO)
            │                     │                    │
┌───────────┼─────────────────────┼────────────────────┼──────────┐
│           │                     │                    │          │
│  ┌────────▼──────────────────────▼────────────────────▼────┐   │
│  │            API GATEWAY / LOAD BALANCER                  │   │
│  │         (AWS ALB / Nginx / Kong)                        │   │
│  └─────────────────┬──────────────────────────────────────┘   │
│                    │                                           │
│  ┌────────────────▼───────────────────────────────────────┐   │
│  │         APPLICATION LAYER (Business Logic)            │   │
│  │                                                         │   │
│  │  ┌──────────────────────────────────────────────────┐ │   │
│  │  │           Express.js Server Cluster              │ │   │
│  │  │  (Multiple instances for load balancing)         │ │   │
│  │  │                                                   │ │   │
│  │  │  ├─ Auth Service                                │ │   │
│  │  │  ├─ SOS Service                                 │ │   │
│  │  │  ├─ Face Recognition Service                    │ │   │
│  │  │  ├─ QR Code Service                             │ │   │
│  │  │  ├─ Notification Service                        │ │   │
│  │  │  ├─ Complaint Service                           │ │   │
│  │  │  └─ User Management Service                     │ │   │
│  │  └──────────────────────────────────────────────────┘ │   │
│  │                                                         │   │
│  │  ┌──────────────────────────────────────────────────┐ │   │
│  │  │           Socket.IO Server                        │ │   │
│  │  │  (Real-time bidirectional communication)          │ │   │
│  │  └──────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────┘   │
│                    │                  │                        │
│  ┌────────────────▼──┐      ┌────────▼──────────────────┐    │
│  │  DATA LAYER       │      │  EXTERNAL SERVICES       │    │
│  │                   │      │                          │    │
│  │  ┌─ MongoDB      │      │  ┌─ Google ML Kit       │    │
│  │  ├─ Redis Cache  │      │  ├─ AWS S3              │    │
│  │  ├─ Message Q    │      │  ├─ SendGrid (Email)    │    │
│  │  └─ File Storage │      │  ├─ Google Maps         │    │
│  │                   │      │  └─ Pinata (IPFS)      │    │
│  └───────────────────┘      └───────────────────────┘    │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### 2.2 System Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| API Server | Node.js + Express | REST API endpoints |
| Real-time | Socket.IO | WebSocket connections |
| Database | MongoDB | Data persistence |
| Cache | Redis | Session, cache, message queue |
| File Storage | AWS S3 / Local | Documents, images, videos |
| Email | Nodemailer / SendGrid | Notifications |
| ML Services | Google ML Kit | Face detection, OCR |
| Maps | Google Maps API | Location visualization |
| Auth | JWT + bcrypt | Authentication |
| Logging | Winston | Application logging |

---

## 3. Data Architecture

### 3.1 Data Model - Entity Relationship Diagram

```
┌─────────────────┐
│     User        │
├─────────────────┤
│ _id (PK)        │◄──────┐
│ email           │       │ 1:N
│ password        │       │
│ name            │       │
│ phone           │       │
│ role            │       │
│ created_at      │       │
└─────────────────┘       │
        ▲                  │
        │ 1:1              │
        │ ┌─────────────────────────────┐
        └─┤ FaceData                    │
          ├─────────────────────────────┤
          │ _id (PK)                    │
          │ user_id (FK) ───────────────┘
          │ face_embedding (encrypted)
          │ registered_at
          └─────────────────────────────┘

┌─────────────────┐
│ Society         │
├─────────────────┤
│ _id (PK)        │◄──────┐
│ name            │       │ 1:N
│ location        │       │
│ agent_id (FK)   │       │
│ created_at      │       │
└─────────────────┘       │
                          │
        ┌─────────────────────────────┐
        │ Guard                       │
        ├─────────────────────────────┤
        │ _id (PK)                    │
        │ user_id (FK)                │
        │ society_id (FK) ────────────┘
        │ status
        │ documents []
        │ created_at
        └─────────────────────────────┘

┌─────────────────┐
│ SOS             │
├─────────────────┤
│ _id (PK)        │
│ resident_id (FK)│
│ location        │
│ status          │
│ created_at      │
│ acknowledged_at │
│ resolved_at     │
│ guard_id (FK)   │
│ face_image      │
│ notes           │
└─────────────────┘

┌─────────────────┐
│ Complaint       │
├─────────────────┤
│ _id (PK)        │
│ resident_id (FK)│
│ description     │
│ category        │
│ attachments []  │
│ status          │
│ assigned_to     │
│ created_at      │
│ resolved_at     │
└─────────────────┘

┌─────────────────┐
│ QRCode          │
├─────────────────┤
│ _id (PK)        │
│ user_id (FK)    │
│ qr_data         │
│ validity_until  │
│ used_count      │
│ created_at      │
└─────────────────┘

┌─────────────────┐
│ Notification    │
├─────────────────┤
│ _id (PK)        │
│ user_id (FK)    │
│ type            │
│ title           │
│ message         │
│ payload         │
│ read            │
│ created_at      │
└─────────────────┘

┌─────────────────┐
│ AuditLog        │
├─────────────────┤
│ _id (PK)        │
│ user_id (FK)    │
│ action          │
│ resource        │
│ changes         │
│ ip_address      │
│ created_at      │
└─────────────────┘
```

### 3.2 Database Schema

#### Users Collection
```javascript
{
  _id: ObjectId,
  email: String (unique, indexed),
  password: String (bcrypt hashed),
  name: String,
  phone: String,
  role: String (enum: resident, guard, agent, police, admin),
  status: String (active, inactive, banned),
  profile: {
    address: String,
    emergency_contacts: [ObjectId], // References to other Users
    bio: String,
    avatar_url: String
  },
  settings: {
    notifications_enabled: Boolean,
    push_notifications: Boolean,
    email_digest: String (daily, weekly, none)
  },
  created_at: Date,
  updated_at: Date,
  last_login: Date,
  deleted_at: Date (soft delete)
}
```

#### SOS Collection
```javascript
{
  _id: ObjectId,
  resident_id: ObjectId (ref: User),
  location: {
    type: "Point",
    coordinates: [longitude, latitude],
    accuracy: Number
  },
  status: String (enum: active, acknowledged, resolved),
  face_image: String (S3 URL),
  face_embedding: Binary (encrypted),
  created_at: Date,
  acknowledged_at: Date,
  acknowledged_by: ObjectId (ref: Guard),
  resolved_at: Date,
  resolved_by: ObjectId (ref: Guard/Agent/Police),
  resolution_notes: String,
  responders: [
    {
      user_id: ObjectId,
      role: String,
      joined_at: Date,
      status: String
    }
  ],
  blockchain_hash: String (optional),
  society_id: ObjectId (ref: Society)
}
```

#### Complaints Collection
```javascript
{
  _id: ObjectId,
  resident_id: ObjectId (ref: User),
  society_id: ObjectId (ref: Society),
  category: String (enum: noise, maintenance, security, other),
  title: String,
  description: String,
  attachments: [
    {
      url: String,
      type: String,
      size: Number,
      uploaded_at: Date
    }
  ],
  status: String (enum: filed, under_review, resolved, closed),
  assigned_to: ObjectId (ref: User),
  priority: String (enum: low, medium, high, urgent),
  responses: [
    {
      user_id: ObjectId,
      message: String,
      attachments: [],
      created_at: Date
    }
  ],
  created_at: Date,
  updated_at: Date,
  resolved_at: Date,
  resolution_notes: String
}
```

#### FaceData Collection
```javascript
{
  _id: ObjectId,
  user_id: ObjectId (ref: User, unique, indexed),
  face_embeddings: [Binary] (encrypted, multiple captures),
  face_images_urls: [String],
  registered_at: Date,
  last_verified_at: Date,
  verification_count: Number,
  is_active: Boolean,
  metadata: {
    age_group: String,
    gender: String (for display purposes)
  }
}
```

#### QRCode Collection
```javascript
{
  _id: ObjectId,
  user_id: ObjectId (ref: User),
  qr_data: String,
  qr_image_url: String,
  validity_until: Date,
  created_at: Date,
  last_used_at: Date,
  used_count: Number,
  is_active: Boolean,
  offline_generated: Boolean
}
```

### 3.3 Indexes

```javascript
// Users
db.users.createIndex({ email: 1 })
db.users.createIndex({ phone: 1 })
db.users.createIndex({ role: 1 })
db.users.createIndex({ created_at: -1 })

// SOS
db.sos.createIndex({ resident_id: 1 })
db.sos.createIndex({ status: 1 })
db.sos.createIndex({ created_at: -1 })
db.sos.createIndex({ location: "2dsphere" }) // Geospatial
db.sos.createIndex({ society_id: 1 })

// Complaints
db.complaints.createIndex({ resident_id: 1 })
db.complaints.createIndex({ status: 1 })
db.complaints.createIndex({ created_at: -1 })

// Face Data
db.facedata.createIndex({ user_id: 1, unique: true })

// Audit Logs
db.auditlogs.createIndex({ user_id: 1 })
db.auditlogs.createIndex({ created_at: -1 })
```

---

## 4. API Architecture

### 4.1 RESTful API Design

#### Base URL
```
https://api.securestep.com/v1
```

#### API Endpoints Structure

```
/api/v1
├── /auth
│   ├── POST /register
│   ├── POST /login
│   ├── POST /logout
│   ├── POST /refresh-token
│   └── POST /forgot-password
│
├── /users
│   ├── GET /:id
│   ├── PUT /:id
│   ├── DELETE /:id
│   ├── GET /list
│   └── PUT /:id/password
│
├── /sos
│   ├── POST /create
│   ├── GET /list
│   ├── GET /:id
│   ├── PUT /:id/acknowledge
│   ├── PUT /:id/resolve
│   ├── GET /active
│   └── GET /history
│
├── /face
│   ├── POST /register
│   ├── POST /verify
│   ├── GET /:userId
│   └── DELETE /:userId
│
├── /qr
│   ├── GET /generate
│   ├── POST /verify
│   ├── GET /list
│   └── DELETE /:id
│
├── /complaints
│   ├── POST /create
│   ├── GET /list
│   ├── GET /:id
│   ├── PUT /:id
│   ├── POST /:id/respond
│   └── PUT /:id/escalate
│
├── /guards
│   ├── POST /register
│   ├── GET /list
│   ├── PUT /:id
│   ├── POST /:id/documents
│   └── GET /:id/jobs
│
├── /societies
│   ├── POST /create
│   ├── GET /list
│   ├── GET /:id
│   └── PUT /:id
│
└── /analytics
    ├── GET /incidents
    ├── GET /metrics
    └── GET /reports
```

### 4.2 Request/Response Format

#### Request Headers
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
X-Request-ID: <UUID>
```

#### Response Format
```json
{
  "success": true,
  "status_code": 200,
  "message": "Operation successful",
  "data": {
    // Payload
  },
  "timestamp": "2026-02-14T10:30:00Z"
}
```

#### Error Response
```json
{
  "success": false,
  "status_code": 400,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {
        "field": "email",
        "message": "Email is invalid"
      }
    ]
  },
  "timestamp": "2026-02-14T10:30:00Z"
}
```

### 4.3 Authentication Flow

```
┌─────────┐                           ┌──────────┐
│ Client  │                           │ Server   │
└────┬────┘                           └────┬─────┘
     │                                     │
     │ 1. POST /auth/login                 │
     │ {email, password}                   │
     ├────────────────────────────────────►│
     │                                     │ 2. Verify credentials
     │                                     │    Generate JWT
     │                                     │ 3. Generate Refresh Token
     │ 4. Return JWT & Refresh Token       │
     │◄────────────────────────────────────┤
     │                                     │
     │ 5. Store JWT (24h) & Refresh (30d) │
     │                                     │
     │ 6. Use JWT for API calls            │
     │ GET /users/me                       │
     │ Authorization: Bearer JWT           │
     ├────────────────────────────────────►│
     │                                     │ 7. Verify JWT signature
     │                                     │    Check expiry
     │ 8. Return user data                 │
     │◄────────────────────────────────────┤
     │                                     │
     │ (JWT expires after 24 hours)        │
     │                                     │
     │ 9. POST /auth/refresh-token         │
     │ {refresh_token}                     │
     ├────────────────────────────────────►│
     │                                     │ 10. Validate refresh token
     │ 11. Return new JWT                  │
     │◄────────────────────────────────────┤
```

---

## 5. Real-Time Architecture

### 5.1 Socket.IO Events

#### Client → Server Events
```javascript
// Connection
'user:connect' → Server knows user is online
'user:location' → User sends location update

// SOS Events
'sos:create' → Create new SOS (mobile only)
'sos:acknowledge' → Guard acknowledges SOS
'sos:update-location' → Resident updates location

// Presence
'user:typing' → User typing on complaint
'user:presence' → Presence sync
```

#### Server → Client Events
```javascript
// SOS Events
'sos:created' → New SOS created (broadcast to guards/agents)
'sos:acknowledged' → SOS acknowledged (to resident)
'sos:resolved' → SOS resolved (to resident & all responders)
'sos:location-updated' → Resident location changed

// Notifications
'notification:new' → New notification
'notification:read' → Notification marked as read

// User Status
'user:online' → User came online
'user:offline' → User went offline

// Dispatch
'dispatch:notification' → Police unit dispatched
'dispatch:arrived' → Unit arrived at location
```

### 5.2 Socket.IO Room Structure

```
/socket.io

├── Rooms by User ID
│   └── user:{userId}
│       └── For personal notifications
│
├── Rooms by Society
│   └── society:{societyId}
│       └── For society-wide events (guards, agents)
│
├── Rooms by Role
│   ├── role:guard
│   ├── role:agent
│   ├── role:police
│   └── role:admin
│
├── Rooms by Event Type
│   ├── event:sos
│   ├── event:complaint
│   └── event:dispatch
│
└── Rooms by Location
    └── location:{lat},{lng},{radius}
        └── For geospatial events
```

### 5.3 Real-Time Flow Example

```
Resident initiates SOS:
┌─────────────────────────────────────────────────────────┐
│ 1. Resident triggers SOS on app                         │
│    ├─ Capture location (GPS)                            │
│    ├─ Capture face image                                │
│    └─ Send POST /sos/create                             │
│                                                          │
│ 2. Backend processes:                                   │
│    ├─ Save SOS to MongoDB                               │
│    ├─ Extract face embedding                            │
│    ├─ Find nearby guards                                │
│    └─ Emit 'sos:created' event                          │
│                                                          │
│ 3. Socket.IO broadcasts to Guards:                      │
│    ├─ Emit to room 'society:{societyId}'                │
│    ├─ Emit to room 'role:guard'                         │
│    ├─ Push notification sent                            │
│    └─ Alert sound plays                                 │
│                                                          │
│ 4. Guard opens app:                                     │
│    ├─ Sees SOS alert with resident location            │
│    ├─ Clicks to verify resident                         │
│    ├─ Takes face photo or scans QR                      │
│    └─ Sends verification result                         │
│                                                          │
│ 5. Backend verifies:                                    │
│    ├─ Compare face embedding (>80% match = pass)        │
│    ├─ Or validate QR signature                          │
│    ├─ Update SOS status to 'acknowledged'               │
│    └─ Emit 'sos:acknowledged' to resident               │
│                                                          │
│ 6. Resident receives acknowledgment:                    │
│    ├─ Notification sent                                 │
│    ├─ Guard name displayed                              │
│    └─ Option to update status                           │
└─────────────────────────────────────────────────────────┘
```

---

## 6. Security Architecture

### 6.1 Authentication & Authorization

```
┌──────────────────────────────────────────────────────────┐
│                   Authentication Layer                   │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. Password Storage (at rest)                           │
│     └─ bcrypt (salt rounds: 12)                          │
│                                                           │
│  2. JWT Token (in transit)                               │
│     ├─ Payload: {userId, role, email, iat, exp}          │
│     ├─ Signing: HS256 with JWT_SECRET                    │
│     └─ Expiry: 24 hours                                  │
│                                                           │
│  3. Refresh Token (long-term)                            │
│     ├─ Stored in Redis with user ID                      │
│     ├─ Expiry: 30 days                                   │
│     └─ Rotating refresh pattern                          │
│                                                           │
│  4. Token Validation                                     │
│     ├─ Signature verification                            │
│     ├─ Expiry check                                      │
│     └─ Blacklist check (revoked tokens)                  │
│                                                           │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                Authorization Layer (RBAC)                │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  Role Definitions:                                       │
│  ├─ Admin: All permissions                               │
│  ├─ Police: View incidents, dispatch, generate reports   │
│  ├─ Agent: Manage guards, monitor SOS, view complaints   │
│  ├─ Guard: Respond to SOS, verify residents              │
│  └─ Resident: Create SOS, file complaints, view history  │
│                                                           │
│  Permission Check:                                       │
│  @RequireRole(['admin', 'agent'])                         │
│  @RequirePermission('sos:acknowledge')                    │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### 6.2 Data Encryption

```
┌────────────────────────────────────────────┐
│         Encryption Strategy                │
├────────────────────────────────────────────┤
│                                            │
│  At Rest (Database):                       │
│  ├─ Passwords: bcrypt (irreversible)       │
│  ├─ Face embeddings: AES-256-GCM          │
│  ├─ PII (name, phone): AES-256-GCM        │
│  ├─ Location history: AES-256-GCM         │
│  └─ Sensitive docs: AES-256-GCM           │
│                                            │
│  In Transit (Network):                     │
│  ├─ All APIs: TLS 1.3                      │
│  ├─ WebSocket: WSS (secure)                │
│  └─ File uploads: HTTPS only               │
│                                            │
│  At Rest (File Storage):                   │
│  ├─ S3 Encryption: AES-256 (SSE-S3)        │
│  ├─ Server-side encryption enabled         │
│  └─ Bucket policies restrict access        │
│                                            │
│  Key Management:                           │
│  ├─ Keys stored in AWS Secrets Manager     │
│  ├─ Automatic key rotation (annual)        │
│  ├─ Different key per environment          │
│  └─ Separate keys for different data types │
│                                            │
└────────────────────────────────────────────┘
```

### 6.3 API Security

```javascript
// Rate Limiting
- Global: 1000 requests/min per IP
- Per User: 100 requests/min
- Per Endpoint: Custom limits

// CORS Configuration
- Allowed Origins: https://frontend.securestep.com
- Allowed Methods: GET, POST, PUT, DELETE
- Allowed Headers: Authorization, Content-Type
- Credentials: true

// Input Validation
- Joi schema validation on all inputs
- Sanitize for XSS attacks
- Parameterized queries for injection prevention

// Rate Limiting Middleware
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: 'Too many requests',
  standardHeaders: true,
  legacyHeaders: false,
}))

// HELMET - Security Headers
app.use(helmet({
  contentSecurityPolicy: true,
  crossOriginEmbedderPolicy: true,
  crossOriginOpenerPolicy: true,
  crossOriginResourcePolicy: true,
  dnsPrefetchControl: true,
  frameguard: { action: 'deny' },
  hidePoweredBy: true,
  hsts: { maxAge: 31536000 },
  ieNoOpen: true,
  noSniff: true,
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
  xssFilter: true,
}))
```

---

## 7. Deployment Architecture

### 7.1 Infrastructure Diagram

```
┌────────────────────────────────────────────────────────┐
│              AWS Cloud Infrastructure                 │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │          CloudFront (CDN)                        │ │
│  │  (Static assets, API caching)                    │ │
│  └────────────────────┬─────────────────────────────┘ │
│                       │                                │
│  ┌────────────────────▼─────────────────────────────┐ │
│  │   AWS ALB (Application Load Balancer)            │ │
│  │   (Distribute traffic, SSL/TLS termination)      │ │
│  └────────┬─────────────────────────┬───────────────┘ │
│           │                         │                 │
│  ┌────────▼──────────┐    ┌────────▼──────────┐      │
│  │ ECS Cluster 1     │    │ ECS Cluster 2     │      │
│  │ (Prod Zone)       │    │ (Backup Zone)     │      │
│  │                   │    │                   │      │
│  │ ┌─────────────┐   │    │ ┌─────────────┐   │      │
│  │ │ Task 1      │   │    │ │ Task 1      │   │      │
│  │ │ Node.js App │   │    │ │ Node.js App │   │      │
│  │ └─────────────┘   │    │ └─────────────┘   │      │
│  │                   │    │                   │      │
│  │ ┌─────────────┐   │    │ ┌─────────────┐   │      │
│  │ │ Task 2      │   │    │ │ Task 2      │   │      │
│  │ │ Node.js App │   │    │ │ Node.js App │   │      │
│  │ └─────────────┘   │    │ └─────────────┘   │      │
│  │                   │    │                   │      │
│  │ ┌─────────────┐   │    │ ┌─────────────┐   │      │
│  │ │ Task N      │   │    │ │ Task N      │   │      │
│  │ │ Node.js App │   │    │ │ Node.js App │   │      │
│  │ └─────────────┘   │    │ └─────────────┘   │      │
│  └─────────────┬─────┘    └────┬────────────┘      │
│                │               │                    │
│  ┌─────────────▼───────────────▼──────────────────┐ │
│  │     RDS Multi-AZ (MongoDB)                     │ │
│  │     Primary: us-east-1a                        │ │
│  │     Secondary: us-east-1b (auto-failover)      │ │
│  └─────────────────────────────────────────────────┘ │
│                                                      │
│  ┌──────────────────┐    ┌──────────────────────┐   │
│  │ ElastiCache      │    │ S3 Bucket            │   │
│  │ (Redis Cluster)  │    │ (File Storage)       │   │
│  │ 3 Nodes (AZ)     │    │ (Versioning, Backup) │   │
│  └──────────────────┘    └──────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │ CloudWatch (Monitoring & Logging)            │   │
│  │ - Logs: All application logs                 │   │
│  │ - Metrics: Performance, errors, requests     │   │
│  │ - Alarms: CPU, memory, error rate            │   │
│  │ - Dashboards: Real-time visualization        │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
└────────────────────────────────────────────────────┘
```

### 7.2 Deployment Pipeline

```
Git Push → GitHub
   │
   ▼
GitHub Actions (CI/CD)
   │
   ├─ Run Tests (Jest)
   ├─ Run Linting (ESLint)
   ├─ Build Docker Image
   ├─ Security Scan (Snyk)
   └─ Push to ECR
   │
   ▼
Staging Environment
   │
   ├─ Deploy to ECS (blue-green)
   ├─ Run Integration Tests
   ├─ Run Performance Tests
   └─ Manual Approval Gate
   │
   ▼
Production Environment
   │
   ├─ Deploy to ECS (canary: 10% traffic)
   ├─ Monitor metrics (5 minutes)
   ├─ Gradually increase traffic (20%, 50%, 100%)
   └─ Rollback if issues detected
```

### 7.3 Docker Configuration

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

# Dependencies
COPY package*.json ./
RUN npm ci --only=production

# Source code
COPY src/ ./src/
COPY config/ ./config/

# Security
RUN npm audit --production

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node healthcheck.js

EXPOSE 5001

CMD ["node", "src/server.js"]
```

### 7.4 Kubernetes (Optional - Future)

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: securestep-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: securestep-api
  template:
    metadata:
      labels:
        app: securestep-api
    spec:
      containers:
      - name: api
        image: securestep-api:latest
        ports:
        - containerPort: 5001
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: mongodb-uri
        livenessProbe:
          httpGet:
            path: /health
            port: 5001
          initialDelaySeconds: 30
          periodSeconds: 10
```

---

## 8. Testing Strategy

### 8.1 Testing Pyramid

```
                    /\
                   /  \
                  /  E2E \
                 /  Tests \
                /____________\
               /              \
              /   Integration  \
             /      Tests      \
            /____________________\
           /                      \
          /    Unit Tests          \
         /____________________________\

Target Coverage:
- Unit Tests:        70%
- Integration:       20%
- E2E:              10%
- Overall:          >80%
```

### 8.2 Test Types

| Test Type | Tool | Focus |
|-----------|------|-------|
| Unit | Jest | Individual functions, services |
| Integration | Jest + Supertest | API endpoints, database |
| E2E | Cypress | User workflows, UI |
| Load | K6 | Performance under load |
| Security | OWASP ZAP | Vulnerabilities |
| API | Postman | API contracts |

### 8.3 CI/CD Testing

```bash
# Pre-commit
npm run lint
npm run type-check

# On commit
npm run test:unit
npm run test:integration

# On PR
npm run test:e2e
npm run security:scan

# Before production
npm run test:load
npm run test:performance
```

---

## 9. Performance Optimization

### 9.1 Database Optimization

```javascript
// Indexing Strategy
- Create indexes on frequently queried fields
- Compound indexes for multi-field queries
- Geospatial indexes for location queries
- TTL indexes for auto-deletion

// Query Optimization
- Limit fields returned (projection)
- Pagination on large result sets
- Lazy loading for nested data
- Query caching in Redis

// Aggregation Pipeline
db.sos.aggregate([
  { $match: { status: 'active' } },
  { $group: { _id: '$society_id', count: { $sum: 1 } } },
  { $sort: { count: -1 } }
])
```

### 9.2 Caching Strategy

```
┌─────────────────────────────────────────┐
│         Multi-Level Caching             │
├─────────────────────────────────────────┤
│                                         │
│  1. Browser Cache (Client)              │
│     ├─ Static assets: 1 year            │
│     ├─ API responses: 5 minutes         │
│     └─ Service worker: offline          │
│                                         │
│  2. CDN Cache (CloudFront)              │
│     ├─ Static assets: 1 month           │
│     ├─ API responses: 1 minute          │
│     └─ Compression: gzip, brotli        │
│                                         │
│  3. Application Cache (Redis)           │
│     ├─ Sessions: 7 days                 │
│     ├─ User data: 1 hour                │
│     ├─ Society data: 1 day              │
│     ├─ Lookup tables: 1 month           │
│     └─ Rate limiting: 15 minutes        │
│                                         │
│  4. Database Query Cache                │
│     ├─ Aggregate results: 1 hour        │
│     ├─ Report data: 1 day               │
│     └─ Analytics: 1 hour                │
│                                         │
└─────────────────────────────────────────┘
```

### 9.3 Response Time Optimization

| Layer | Target | Strategy |
|-------|--------|----------|
| API Response | <500ms | Optimize queries, caching |
| Face Recognition | <3s | Client-side preprocessing |
| QR Scan | <2s | Offline model, lazy loading |
| Page Load | <3s | Code splitting, CDN |
| WebSocket | <1s | Binary protocol, compression |

---

## 10. Monitoring & Observability

### 10.1 Metrics to Track

```javascript
// Application Metrics
- Request count by endpoint
- Response time (p50, p95, p99)
- Error rate by endpoint
- Authentication attempts (success/failure)
- Face recognition accuracy
- QR code scan success rate

// Infrastructure Metrics
- CPU utilization
- Memory usage
- Disk space
- Network throughput
- Database connections
- Cache hit ratio

// Business Metrics
- Active users (DAU, MAU)
- SOS response time
- Guard verification time
- Complaint resolution time
- System uptime
```

### 10.2 Alerting Rules

```yaml
# Alert Rules (Prometheus)
- name: HighErrorRate
  condition: error_rate > 1%
  duration: 5m
  action: Page on-call

- name: HighResponseTime
  condition: p99_response_time > 1s
  duration: 10m
  action: Notify team

- name: DatabaseDown
  condition: db_connection_error > 5
  duration: 1m
  action: Page on-call

- name: DiskSpaceLow
  condition: disk_free < 10%
  duration: 1m
  action: Notify ops
```

---

## 11. Disaster Recovery

### 11.1 Backup Strategy

```
Daily Backup Schedule:
├─ 00:00 UTC: Full database backup
├─ 06:00 UTC: Incremental backup
├─ 12:00 UTC: Incremental backup
└─ 18:00 UTC: Incremental backup

Backup Locations:
├─ Primary: AWS S3 (us-east-1)
├─ Secondary: AWS S3 (eu-west-1)
└─ Tertiary: On-premise cold storage

Retention Policy:
├─ Daily: 7 days
├─ Weekly: 4 weeks
├─ Monthly: 12 months
└─ Yearly: 7 years (compliance)

Recovery Testing:
├─ Monthly: Test restore from backup
├─ Quarterly: Full disaster recovery drill
└─ Log: All recovery tests documented
```

### 11.2 RTO & RPO

| Scenario | RTO | RPO |
|----------|-----|-----|
| Single server failure | 5 mins | 0 mins (no data loss) |
| Zone failure | 10 mins | <1 min |
| Region failure | 30 mins | <5 mins |
| Data corruption | 1 hour | <15 mins |

---

## 12. Technology Stack Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| Runtime | Node.js | 18+ |
| Framework | Express.js | 4.18+ |
| Language | JavaScript/Dart | ES2020+/Dart 3.x |
| Database | MongoDB | 5.0+ |
| Cache | Redis | 7.0+ |
| Real-time | Socket.IO | 4.5+ |
| Auth | JWT + bcrypt | - |
| Logging | Winston | 3.8+ |
| Testing | Jest | 29+ |
| API Docs | Swagger/OpenAPI | 3.0 |
| Container | Docker | 20+ |
| Orchestration | AWS ECS | - |

---

## Document Approval

**Prepared By**: Development Team  
**Reviewed By**: Technical Lead  
**Approved By**: Project Manager  
**Date**: February 14, 2026  
**Version**: 1.0  
**Status**: Approved for Implementation

---

**Document History**:
- v1.0 (Feb 14, 2026): Initial system design document
