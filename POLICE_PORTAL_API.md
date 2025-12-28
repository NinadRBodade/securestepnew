# Police Portal API Documentation

## Overview
This document describes the API endpoints required for the Police Portal web application to receive and manage SOS alerts from the Society Safety mobile app.

## Base URL
```
https://api.societysafety.com/v1
```

## Authentication
All API requests must include an API key in the header:
```
Authorization: Bearer <API_KEY>
```

---

## Endpoints

### 1. Receive SOS Alert (Webhook)
**POST** `/api/sos/alert`

Receives new SOS alerts from the mobile app.

**Request Body:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "resident@example.com",
  "userName": "Ramesh Singh",
  "userRole": "resident",
  "flatNumber": "A-234",
  "timestamp": "2024-01-15T10:30:00Z",
  "latitude": "19.0760",
  "longitude": "72.8777",
  "locationAddress": "123 Main Street, Andheri, Mumbai, Maharashtra, 400053",
  "status": "active",
  "agentId": null,
  "agentName": null,
  "agentCompany": null,
  "description": "Suspicious Person: Unknown person loitering near gate",
  "photoPath": null,
  "guardId": null,
  "acknowledgedAt": null,
  "resolvedAt": null,
  "resolutionNotes": null,
  "isSynced": false,
  "blockchainHash": null
}
```

**Response:**
```json
{
  "success": true,
  "message": "SOS alert received",
  "alertId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-15T10:30:01Z"
}
```

---

### 2. Get All SOS Alerts
**GET** `/api/sos/alerts`

Retrieves all SOS alerts with optional filters.

**Query Parameters:**
- `status` (optional): Filter by status (active, acknowledged, resolved, false_alarm)
- `startDate` (optional): Start date for filtering (ISO 8601 format)
- `endDate` (optional): End date for filtering (ISO 8601 format)
- `societyId` (optional): Filter by society ID
- `page` (optional): Page number for pagination (default: 1)
- `limit` (optional): Number of results per page (default: 50)

**Example Request:**
```
GET /api/sos/alerts?status=active&page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "userId": "resident@example.com",
      "userName": "Ramesh Singh",
      "userRole": "resident",
      "flatNumber": "A-234",
      "timestamp": "2024-01-15T10:30:00Z",
      "latitude": "19.0760",
      "longitude": "72.8777",
      "locationAddress": "123 Main Street, Andheri, Mumbai, Maharashtra, 400053",
      "status": "active",
      "description": "Medical Emergency: Person unconscious",
      "societyName": "Green Valley Apartments",
      "societyAddress": "Andheri West, Mumbai"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

---

### 3. Get Alert by ID
**GET** `/api/sos/alerts/{alertId}`

Retrieves a specific SOS alert by its ID.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "userId": "resident@example.com",
    "userName": "Ramesh Singh",
    "userRole": "resident",
    "flatNumber": "A-234",
    "timestamp": "2024-01-15T10:30:00Z",
    "latitude": "19.0760",
    "longitude": "72.8777",
    "locationAddress": "123 Main Street, Andheri, Mumbai, Maharashtra, 400053",
    "status": "acknowledged",
    "description": "Medical Emergency: Person unconscious",
    "guardId": "guard@example.com",
    "acknowledgedAt": "2024-01-15T10:32:00Z",
    "resolvedAt": null,
    "resolutionNotes": null,
    "societyDetails": {
      "name": "Green Valley Apartments",
      "address": "Andheri West, Mumbai",
      "phone": "+91-9876543210",
      "policeStation": "Andheri Police Station"
    }
  }
}
```

---

### 4. Update Alert Status (Police)
**PATCH** `/api/sos/alerts/{alertId}/status`

Allows police to update the status of an SOS alert.

**Request Body:**
```json
{
  "status": "police_dispatched",
  "policeOfficerId": "PO12345",
  "policeOfficerName": "Inspector Sharma",
  "notes": "Police team dispatched from Andheri station",
  "estimatedArrival": "2024-01-15T10:45:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Alert status updated",
  "alertId": "550e8400-e29b-41d4-a716-446655440000",
  "newStatus": "police_dispatched"
}
```

---

### 5. Get Real-time Alerts (WebSocket)
**WebSocket** `wss://api.societysafety.com/v1/ws/sos/alerts`

Establishes a WebSocket connection for real-time SOS alerts.

**Connection:**
```javascript
const ws = new WebSocket('wss://api.societysafety.com/v1/ws/sos/alerts?apiKey=YOUR_API_KEY');

ws.onmessage = (event) => {
  const alert = JSON.parse(event.data);
  console.log('New SOS Alert:', alert);
};
```

**Message Format:**
```json
{
  "type": "new_alert",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "userName": "Ramesh Singh",
    "flatNumber": "A-234",
    "timestamp": "2024-01-15T10:30:00Z",
    "latitude": "19.0760",
    "longitude": "72.8777",
    "status": "active",
    "description": "Medical Emergency",
    "priority": "high"
  }
}
```

---

### 6. Get Alert Statistics
**GET** `/api/sos/stats`

Retrieves statistics about SOS alerts.

**Query Parameters:**
- `startDate` (required): Start date (ISO 8601 format)
- `endDate` (required): End date (ISO 8601 format)
- `societyId` (optional): Filter by society

**Response:**
```json
{
  "success": true,
  "data": {
    "totalAlerts": 150,
    "activeAlerts": 5,
    "acknowledgedAlerts": 12,
    "resolvedAlerts": 128,
    "falseAlarms": 5,
    "averageResponseTime": 180,
    "alertsByType": {
      "Suspicious Person": 45,
      "Medical Emergency": 30,
      "Fire": 5,
      "Theft": 20,
      "Violence": 15,
      "Other": 35
    },
    "alertsByHour": {
      "0": 2, "1": 1, "2": 0, "3": 0, "4": 1,
      "5": 3, "6": 5, "7": 8, "8": 12, "9": 10,
      "10": 15, "11": 12, "12": 10, "13": 8, "14": 9,
      "15": 7, "16": 6, "17": 8, "18": 12, "19": 10,
      "20": 6, "21": 4, "22": 3, "23": 3
    }
  }
}
```

---

### 7. Get Nearby Societies
**GET** `/api/sos/societies/nearby`

Gets list of societies near a specific location.

**Query Parameters:**
- `latitude` (required): Latitude of location
- `longitude` (required): Longitude of location
- `radius` (optional): Radius in km (default: 5)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "societyId": "SOC001",
      "name": "Green Valley Apartments",
      "address": "Andheri West, Mumbai",
      "latitude": "19.0760",
      "longitude": "72.8777",
      "distance": 0.5,
      "contactPhone": "+91-9876543210",
      "totalResidents": 250,
      "activeGuards": 3
    }
  ]
}
```

---

## Map Integration

### GeoJSON Format for Map Display

The police portal should display SOS alerts on an interactive map. Here's the recommended GeoJSON format:

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [72.8777, 19.0760]
      },
      "properties": {
        "alertId": "550e8400-e29b-41d4-a716-446655440000",
        "userName": "Ramesh Singh",
        "flatNumber": "A-234",
        "status": "active",
        "description": "Medical Emergency",
        "timestamp": "2024-01-15T10:30:00Z",
        "priority": "high",
        "markerColor": "#FF0000"
      }
    }
  ]
}
```

### Map Marker Colors
- **Red (#FF0000)**: Active alerts (high priority)
- **Orange (#FFA500)**: Acknowledged alerts (in progress)
- **Green (#00FF00)**: Resolved alerts
- **Gray (#808080)**: False alarms

---

## Error Responses

All endpoints return consistent error responses:

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Missing required field: latitude",
    "details": {
      "field": "latitude",
      "reason": "Required field is missing"
    }
  }
}
```

### Error Codes
- `INVALID_REQUEST`: Invalid request parameters
- `UNAUTHORIZED`: Invalid or missing API key
- `NOT_FOUND`: Resource not found
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_ERROR`: Server error

---

## Rate Limiting

- **Standard API calls**: 1000 requests per hour per API key
- **WebSocket connections**: 5 concurrent connections per API key

When rate limit is exceeded:
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Retry after 3600 seconds",
    "retryAfter": 3600
  }
}
```

---

## Security Considerations

1. **API Keys**: Store securely, rotate periodically
2. **HTTPS Only**: All API calls must use HTTPS
3. **IP Whitelisting**: Restrict API access to known IP addresses
4. **Data Encryption**: All sensitive data encrypted in transit and at rest
5. **Audit Logging**: All API calls logged for security audit

---

## Police Portal Features

The police web portal should include:

### Dashboard
- Real-time alert counter (active, acknowledged, resolved)
- Interactive map showing all active alerts
- Recent alerts list
- Alert statistics and trends

### Alert Details Page
- Complete alert information
- User details and contact
- Location on map with directions
- Timeline of actions
- Response form for police actions

### Map View
- Clustered markers for multiple alerts in same area
- Color-coded by status and priority
- Click on marker to see alert details
- Draw radius tools for area analysis
- Heatmap view for alert density

### Reports & Analytics
- Alert trends over time
- Response time analysis
- Alert types breakdown
- Geographic distribution
- Performance metrics

### Settings
- API key management
- Notification preferences
- User access control
- Society database management

---

## Sample Integration Code

### JavaScript (Fetch API)
```javascript
async function getActiveAlerts() {
  const response = await fetch('https://api.societysafety.com/v1/api/sos/alerts?status=active', {
    headers: {
      'Authorization': 'Bearer YOUR_API_KEY',
      'Content-Type': 'application/json'
    }
  });
  
  const data = await response.json();
  return data.data;
}
```

### Python (Requests)
```python
import requests

def get_active_alerts():
    headers = {
        'Authorization': 'Bearer YOUR_API_KEY',
        'Content-Type': 'application/json'
    }
    
    response = requests.get(
        'https://api.societysafety.com/v1/api/sos/alerts',
        params={'status': 'active'},
        headers=headers
    )
    
    return response.json()['data']
```

---

## Testing

Use the following test API key for development:
```
TEST_API_KEY: test_key_1234567890abcdef
```

Test endpoint:
```
https://api-test.societysafety.com/v1
```

---

## Support

For API support and questions:
- Email: api-support@societysafety.com
- Documentation: https://docs.societysafety.com
- Status Page: https://status.societysafety.com
