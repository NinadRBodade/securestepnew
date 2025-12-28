# Quick Endpoint Testing

## Test SOS Endpoint

```bash
curl http://localhost:5001/api/sos
```

Expected response:
```json
{
  "status": "success",
  "data": {
    "events": [],
    "count": 0
  }
}
```

## Test Society List Endpoint

```bash
curl http://localhost:5001/api/society/list
```

Expected response:
```json
{
  "success": true,
  "societies": [
    {
      "_id": "...",
      "name": "Society Name",
      "city": "City",
      "state": "State"
    }
  ],
  "count": 1
}
```

## Open Admin Panel

Navigate to: http://localhost:8080/admin_portal/

1. Click "🚨 SOS Alerts" in sidebar
2. Should see "No SOS alerts found" (if no SOS triggered yet)
3. Go to "Societies" section
4. Create a test society
5. Go to Flutter app and verify society appears in dropdown

## Test SOS Alert Flow

1. Open Flutter app (User → Society → Login)
2. Go to resident SOS screen
3. Click "TRIGGER SOS"
4. Go back to Admin Panel
5. Click "SOS Alerts"
6. Should see the new SOS alert with:
   - Status badge (red "ACTIVE")
   - User name
   - Flat number
   - Time (e.g., "Just now")
   - Actions (Acknowledge, Resolve, View Details)

## Verify Console Logs

### Backend Console:
```
📋 Fetching society list for user dropdown...
✅ Found N active societies

📊 Retrieved N SOS events from MongoDB
```

### Browser Console (F12):
```
📡 Fetching SOS alerts from API...
Response status: 200
📊 SOS data received: {...}
✅ Loaded N SOS alerts
```
