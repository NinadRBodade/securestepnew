# Testing Frontend-Backend Integration

## ✅ Backend Running
- Port: 5001
- Status: Connected to MongoDB
- Health: http://localhost:5001/health

## ✅ Flutter App Running
- Emulator: sdk gphone64 arm64
- Base URL: http://10.0.2.2:5001

## Testing Steps:

### 1. Test Backend Health (from computer terminal):
```bash
curl http://localhost:5001/health
```
Expected: `{"status":"OK","message":"Backend running"}`

### 2. Test from Emulator (simulates Flutter):
```bash
curl http://10.0.2.2:5001/health
```
This uses the emulator's special IP to reach your Mac's localhost

### 3. Test Login API:
```bash
curl -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'
```

### 4. In Flutter App:
- Open the app on emulator
- Navigate through screens
- Watch the backend terminal for incoming requests
- Try to login or trigger any API call
- Backend will show: `POST /api/auth/...` or `GET /api/...`

### 5. Test SOS Alert:
- In Flutter app, go to SOS screen
- Click emergency button
- Backend should log: `POST /api/sos/alert`
- Check backend terminal for the request

## Troubleshooting:

If Flutter can't connect to backend:
1. Verify backend is running: `lsof -i:5001`
2. Check Flutter constants.dart has: `http://10.0.2.2:5001`
3. Restart Flutter app if needed
4. Check backend terminal for errors

## Success Indicators:
✅ Backend shows API requests when you use the app
✅ App doesn't show connection errors
✅ Data flows between Flutter and MongoDB
