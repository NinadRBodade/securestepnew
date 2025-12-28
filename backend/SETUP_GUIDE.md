# Backend Setup Guide

## ✅ What's Configured

The backend is **fully integrated** with your Flutter app and ready to run!

### Features Implemented:
- ✅ MongoDB connection with Mongoose
- ✅ JWT authentication
- ✅ SOS Alert System (matches Flutter app exactly)
- ✅ Socket.IO for real-time updates
- ✅ REST API endpoints
- ✅ Error handling middleware
- ✅ CORS enabled for mobile app

---

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
cd backend
npm install
```

### Step 2: Configure MongoDB

The `.env` file is already created with MongoDB URI. If you need to change it:

1. Open `backend/.env`
2. Update `MONGODB_URI` with your MongoDB connection string

**Current MongoDB URI:**
```
mongodb+srv://swapnil:Test1234@cluster0.lqyfuxz.mongodb.net/society_safety?retryWrites=true&w=majority
```

### Step 3: Start the Server

```bash
npm run dev
```

You should see:
```
✅ MongoDB connected successfully
🚀 Server running on port 5000
```

---

## 📱 Connect Flutter App to Backend

### For Android Emulator:

The Flutter app is already configured to use `http://10.0.2.2:5000` which points to your localhost.

**No changes needed!** Just run the backend and the app will connect.

### For Real Android Device:

1. Find your computer's IP address:
   ```bash
   # On Mac/Linux
   ifconfig | grep "inet "
   
   # On Windows
   ipconfig
   ```

2. Open `lib/utils/constants.dart`

3. Update line 6:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:5000'; // Replace YOUR_IP
   ```
   Example: `http://192.168.1.100:5000`

4. Ensure your phone and computer are on the same WiFi network

---

## 🔌 API Endpoints

All endpoints are prefixed with `/api`

### Authentication
- **POST** `/api/auth/register` - Register new user
- **POST** `/api/auth/login` - Login user

### SOS System
- **POST** `/api/sos/alert` - Trigger SOS (no auth required for emergency)
- **GET** `/api/sos/alerts` - Get all SOS events (auth required)
- **GET** `/api/sos/alerts/:id` - Get specific SOS event
- **PATCH** `/api/sos/alerts/:id/acknowledge` - Guard acknowledges alert
- **PATCH** `/api/sos/alerts/:id/resolve` - Guard resolves alert
- **PATCH** `/api/sos/alerts/:id/false-alarm` - Mark as false alarm
- **GET** `/api/sos/stats` - Get SOS statistics

### Test Endpoints
- **GET** `/health` - Check if server is running

---

## 🧪 Testing the Integration

### Test 1: Backend Health Check

```bash
curl http://localhost:5000/health
```

Expected response:
```json
{"status":"OK","message":"Backend running"}
```

### Test 2: Send SOS from Flutter App

1. Start backend: `npm run dev`
2. Start Flutter app: `flutter run`
3. Login as resident (resident@demo.com / resident123)
4. Tap "SOS Alert"
5. Select emergency type
6. Tap "SEND SOS ALERT"

You should see in backend terminal:
```
✅ SOS sent to server: 507f1f77bcf86cd799439011
```

### Test 3: View SOS in Guard Dashboard

1. Open another instance of the app (or use real device)
2. Login as guard (guard@demo.com / guard123)
3. Tap "SOS Alerts"
4. You should see the SOS alert from resident

---

## 🔄 Real-time Updates (Socket.IO)

The backend emits real-time events when:
- New SOS alert is triggered → `sos:new`
- SOS status changes → `sos:update`

Guards automatically receive updates via Socket.IO connection.

---

## 📊 Database Collections

MongoDB will automatically create these collections:

1. **users** - All app users (agents, residents, guards, admins)
2. **sosevents** - Emergency alerts
3. **agents** - Agent-specific data (face embeddings, QR codes)
4. **residents** - Resident-specific data
5. **visits** - Entry/exit logs (coming soon)

---

## 🛠️ Troubleshooting

### Error: MongoDB connection failed

**Solution:** Check your MongoDB URI in `.env` file. Make sure:
- Username and password are correct
- Database name exists
- Network access is allowed (whitelist your IP in MongoDB Atlas)

### Error: Port 5000 already in use

**Solution:** Change port in `.env`:
```
PORT=3000
```

Then update Flutter app constants:
```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

### Error: CORS blocked

**Solution:** CORS is already configured to allow all origins. If issues persist, check:
```javascript
// In server.js
app.use(cors()); // Should be before routes
```

### Flutter app can't connect

**Checklist:**
- ✅ Backend is running (`npm run dev`)
- ✅ No firewall blocking port 5000
- ✅ Using correct IP (10.0.2.2 for emulator)
- ✅ Same WiFi network (for real device)

---

## 📁 Project Structure

```
backend/
├── .env                    # Environment variables
├── .env.example           # Environment template
├── package.json           # Dependencies
└── src/
    ├── server.js          # Main entry point ✅
    ├── config/
    │   ├── database.js    # MongoDB connection ✅
    │   ├── socket.js      # Socket.IO setup ✅
    │   └── constants.js   # App constants
    ├── models/
    │   ├── User.js        # User schema ✅
    │   └── SOSEvent.js    # SOS schema ✅
    ├── controllers/
    │   ├── auth.controller.js   # Auth logic ✅
    │   └── sos.controller.js    # SOS logic ✅
    ├── routes/
    │   ├── auth.routes.js       # Auth endpoints ✅
    │   └── sos.routes.js        # SOS endpoints ✅
    ├── middleware/
    │   ├── auth.middleware.js   # JWT verification ✅
    │   └── error.middleware.js  # Error handler ✅
    └── services/
        └── socket.service.js    # Real-time events ✅
```

---

## 🎯 Next Steps

### Priority 1: Test Complete Flow
1. ✅ Start backend
2. ✅ Register new user
3. ✅ Login
4. ✅ Trigger SOS
5. ✅ View in guard dashboard

### Priority 2: Implement Agent Features
- QR code generation
- Face registration upload
- Agent verification

### Priority 3: Implement Visit Logging
- Entry/exit tracking
- Visit history
- Guard approval

### Priority 4: Add Push Notifications
- Firebase Cloud Messaging
- Real-time alerts even when app closed

---

## 📝 Important Notes

### Security
- 🔒 JWT tokens expire after 7 days
- 🔒 Passwords are hashed with bcrypt
- 🔒 SOS endpoint is public (no auth) for emergency access
- 🔒 All other endpoints require authentication

### Data Flow
```
Flutter App → HTTP Request → Express Server → MongoDB
                                     ↓
                              Socket.IO Emit
                                     ↓
                           Guard App (Real-time)
```

### Production Checklist
Before deploying:
- [ ] Change `JWT_SECRET` to strong random string
- [ ] Enable MongoDB IP whitelist (remove 0.0.0.0/0)
- [ ] Set `NODE_ENV=production`
- [ ] Use HTTPS (not HTTP)
- [ ] Enable rate limiting
- [ ] Add request logging
- [ ] Set up monitoring (PM2, New Relic, etc.)

---

## 🆘 Support

If you encounter issues:

1. Check backend logs in terminal
2. Check Flutter console for errors
3. Verify MongoDB connection
4. Test with Postman/curl first
5. Check network connectivity

---

## ✨ What's Working Now

- ✅ User registration and login
- ✅ JWT authentication
- ✅ SOS alert creation
- ✅ SOS alert listing
- ✅ Guard acknowledge/resolve
- ✅ Real-time Socket.IO events
- ✅ MongoDB data persistence
- ✅ Error handling
- ✅ CORS for mobile

**You're ready to go! 🚀**

Run `npm run dev` and start testing!
