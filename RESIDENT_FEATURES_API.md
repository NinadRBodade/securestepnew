# Resident Features API Documentation

## Overview
This document describes the backend APIs for resident features. All endpoints require JWT authentication via Bearer token in Authorization header.

---

## 1. Profile Management

### Get Profile
```
GET /api/residents/profile
```
**Response:**
```json
{
  "status": "success",
  "data": {
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "1234567890",
    "flatNumber": "A-101",
    "emergencyPreference": "both"
  }
}
```

### Update Profile
```
PUT /api/residents/profile
Content-Type: application/json

{
  "name": "John Doe",
  "phone": "9876543210",
  "emergencyPreference": "sms"
}
```
**Response:**
```json
{
  "status": "success",
  "message": "Profile updated successfully"
}
```

---

## 2. Notification Settings

### Get Notification Settings
```
GET /api/residents/settings
```
**Response:**
```json
{
  "status": "success",
  "data": {
    "pushEnabled": true,
    "smsEnabled": false
  }
}
```

### Update Notification Settings
```
PUT /api/residents/settings
Content-Type: application/json

{
  "pushEnabled": true,
  "smsEnabled": true
}
```
**Response:**
```json
{
  "status": "success",
  "message": "Settings updated successfully"
}
```

---

## 3. Emergency Contacts

### Get Emergency Contacts
```
GET /api/residents/contacts
```
**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "_id": "64abc123...",
      "name": "Jane Doe",
      "relation": "Spouse",
      "phone": "9876543210"
    }
  ]
}
```

### Add Emergency Contact
```
POST /api/residents/contacts
Content-Type: application/json

{
  "name": "Jane Doe",
  "relation": "Spouse",
  "phone": "9876543210"
}
```
**Response:**
```json
{
  "status": "success",
  "message": "Contact added successfully",
  "data": {
    "_id": "64abc123...",
    "name": "Jane Doe",
    "relation": "Spouse",
    "phone": "9876543210"
  }
}
```

### Delete Emergency Contact
```
DELETE /api/residents/contacts/:id
```
**Response:**
```json
{
  "status": "success",
  "message": "Contact deleted successfully"
}
```

---

## 4. SOS History

### Get User's SOS Events
```
GET /api/sos?mine=true
```
**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "_id": "64abc...",
      "sosId": "SOS-123456",
      "triggeredBy": {
        "userId": "user123",
        "name": "John Doe",
        "role": "resident"
      },
      "flatNumber": "A-101",
      "location": {
        "latitude": 28.7041,
        "longitude": 77.1025,
        "address": "Near Main Gate"
      },
      "description": "Medical emergency",
      "status": "resolved",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

## 5. Guard Contact

### Get Guard Information for SOS
```
GET /api/sos/:id/guard
```
**Response:**
```json
{
  "status": "success",
  "data": {
    "sosId": "SOS-123456",
    "status": "active",
    "guards": [
      {
        "name": "Guard Kumar",
        "phone": "9999888877",
        "email": "guard@society.com"
      }
    ]
  }
}
```

**Access Control:**
- Residents can only access guard info for their own SOS events
- Guards/admins can access guard info for any SOS event

---

## 6. Complaint System

### Create Complaint
```
POST /api/complaints
Content-Type: application/json

{
  "title": "Broken streetlight",
  "description": "Street light near gate 2 is not working",
  "category": "maintenance"
}
```
**Categories:** `maintenance`, `security`, `cleanliness`, `noise`, `parking`, `other`

**Response:**
```json
{
  "status": "success",
  "message": "Complaint submitted successfully",
  "data": {
    "_id": "64abc...",
    "title": "Broken streetlight",
    "description": "Street light near gate 2 is not working",
    "category": "maintenance",
    "status": "open",
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

### Get User's Complaints
```
GET /api/complaints?mine=true
```
**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "_id": "64abc...",
      "title": "Broken streetlight",
      "description": "Street light near gate 2 is not working",
      "category": "maintenance",
      "status": "in_progress",
      "userName": "John Doe",
      "flatNumber": "A-101",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Get Complaint Details
```
GET /api/complaints/:id
```
**Response:**
```json
{
  "status": "success",
  "data": {
    "_id": "64abc...",
    "title": "Broken streetlight",
    "description": "Street light near gate 2 is not working",
    "category": "maintenance",
    "status": "resolved",
    "userName": "John Doe",
    "flatNumber": "A-101",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-16T14:20:00Z"
  }
}
```

### Update Complaint Status (Admin/Guard Only)
```
PUT /api/complaints/:id/status
Content-Type: application/json

{
  "status": "resolved"
}
```
**Allowed Status Values:** `open`, `in_progress`, `resolved`, `closed`

**Response:**
```json
{
  "status": "success",
  "message": "Complaint status updated successfully"
}
```

---

## 7. Visit History (Existing)

### Get Visit History
```
GET /api/residents/visits
```
**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "visitorName": "Alice Johnson",
      "purpose": "Social visit",
      "date": "2024-01-15",
      "status": "completed"
    }
  ]
}
```

---

## Authentication

All endpoints require Bearer token authentication:
```
Authorization: Bearer <JWT_TOKEN>
```

The JWT token contains:
- `id`: User ID
- `role`: User role (resident, guard, admin)
- `name`: User name
- `email`: User email
- `phone`: Phone number
- `societyId`: Society ID
- `flatNumber`: Flat number

---

## Error Responses

All endpoints return consistent error responses:

```json
{
  "status": "error",
  "message": "Error description",
  "error": "Detailed error message (development only)"
}
```

**Common HTTP Status Codes:**
- `200`: Success
- `201`: Created
- `400`: Bad request (validation error)
- `401`: Unauthorized (missing/invalid token)
- `403`: Forbidden (insufficient permissions)
- `404`: Not found
- `500`: Internal server error

---

## Database Models

### NotificationSettings
```javascript
{
  userId: String (unique),
  pushEnabled: Boolean (default: true),
  smsEnabled: Boolean (default: false),
  createdAt: Date,
  updatedAt: Date
}
```

### EmergencyContact
```javascript
{
  userId: String (indexed),
  name: String (required),
  relation: String (required),
  phone: String (required),
  createdAt: Date,
  updatedAt: Date
}
```

### Complaint
```javascript
{
  userId: String (required),
  userName: String (required),
  flatNumber: String (required),
  title: String (required),
  description: String (required),
  category: Enum (maintenance, security, cleanliness, noise, parking, other),
  status: Enum (open, in_progress, resolved, closed) - default: 'open',
  createdAt: Date,
  updatedAt: Date
}
```

---

## Testing Instructions

### 1. Start Backend
```bash
cd backend
npm start
```

### 2. Login to Get Token
```bash
curl -X POST http://10.20.210.17:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"resident@test.com","password":"password123"}'
```

### 3. Test Profile API
```bash
curl -X GET http://10.20.210.17:5001/api/residents/profile \
  -H "Authorization: Bearer <TOKEN>"
```

### 4. Test Settings API
```bash
curl -X PUT http://10.20.210.17:5001/api/residents/settings \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"pushEnabled":true,"smsEnabled":true}'
```

### 5. Test Contact API
```bash
curl -X POST http://10.20.210.17:5001/api/residents/contacts \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Emergency Contact","relation":"Friend","phone":"9999999999"}'
```

### 6. Test SOS History
```bash
curl -X GET "http://10.20.210.17:5001/api/sos?mine=true" \
  -H "Authorization: Bearer <TOKEN>"
```

### 7. Test Complaint API
```bash
curl -X POST http://10.20.210.17:5001/api/complaints \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Complaint","description":"This is a test","category":"maintenance"}'
```

---

## Frontend Integration Notes

### Flutter Integration
1. All APIs already integrated in Flutter app UI
2. Backend endpoints now functional
3. Update API base URL: `http://10.20.210.17:5001`
4. JWT token stored in secure storage, passed in Authorization header
5. No UI changes required - existing screens will work automatically

### Feature Mapping
- `ProfileScreen` → `/api/residents/profile`
- `SettingsScreen` → `/api/residents/settings`
- `EmergencyContactsScreen` → `/api/residents/contacts`
- `SOSHistoryScreen` → `/api/sos?mine=true`
- `ViewGuardContactScreen` → `/api/sos/:id/guard`
- `ComplaintsScreen` → `/api/complaints`

---

## Security Notes

1. **Authentication Required**: All endpoints require valid JWT token
2. **Authorization**: 
   - Residents can only access their own data
   - Guards/Admins have additional permissions (update complaint status)
3. **No Blockchain Hash Exposure**: SOS endpoints sanitize response to hide blockchain hash from residents
4. **Data Privacy**: User can only see their own profile, settings, contacts, SOS, and complaints
5. **Input Validation**: All inputs validated using Joi schemas

---

## MongoDB Collections

After implementing these features, MongoDB will have:
- `users` - User accounts (existing)
- `sosevents` - Emergency alerts (existing)
- `notificationsettings` - Notification preferences (NEW)
- `emergencycontacts` - Emergency contacts (NEW)
- `complaints` - Complaint tickets (NEW)
- `visits` - Visit records (existing)

---

## Status

✅ All backend APIs implemented and functional
✅ Routes registered in server.js
✅ MongoDB models created
✅ Controllers implemented with error handling
✅ Authentication and authorization middleware applied
✅ Ready for frontend integration testing
