# Face Recognition Backend Integration - Testing Guide

## Overview
The face recognition feature has been updated to work with **real backend data** instead of demo/mock data. This document provides testing instructions to verify the complete flow.

## Changes Implemented

### 1. Backend API Endpoints
**Location:** `backend/src/routes/face.routes.js`

New endpoints created:
- `POST /api/face/upload` - Upload agent face image
- `GET /api/face/image/:email` - Retrieve face image by email
- `GET /api/face/check/:email` - Check if face is registered
- `DELETE /api/face/delete/:email` - Remove face registration

### 2. Flutter Agent Registration
**File:** `lib/screens/agent/agent_face_registration_screen.dart`

**Updated Features:**
- **Dual Storage**: Saves face locally AND uploads to backend
- **Backend Upload**: Uploads face image to `/api/face/upload` after capture
- **Error Handling**: Continues if backend upload fails (offline support)

**Flow:**
1. Agent captures face with camera
2. ML Kit validates face quality (angles, single face, etc.)
3. Saves to local storage: `/agent_faces/{email}.jpg`
4. Uploads to backend: `POST /api/face/upload`
5. Shows success message

### 3. Flutter Resident Verification
**File:** `lib/screens/resident/resident_face_verification_screen.dart`

**Updated Features:**
- **Backend Download**: Fetches registered face from backend first
- **Fallback to Local**: Uses local storage if backend unavailable
- **Real-time Verification**: Compares live face with backend data

**Flow:**
1. Downloads registered face from `GET /api/face/image/{email}`
2. If backend unavailable, checks local storage
3. Captures live face from camera
4. Compares using ML Kit (face landmarks, angles, bounds)
5. Shows match score (70% threshold for verification)

## Testing Instructions

### Prerequisites
✅ Backend server running on port 5001
✅ MongoDB connected successfully
✅ Flutter app with http 1.1.0 package installed
✅ Camera permissions granted on device

### Test 1: Agent Face Registration with Backend Upload

**Steps:**
1. **Login as Agent**
   - Email: `sam@gmail.com` (or any registered agent)
   - Password: Agent's password

2. **Navigate to Dashboard**
   - Tap "Agent Dashboard" from role selection

3. **Register Face**
   - Tap "Register Face" button
   - Allow camera permissions if prompted
   - Position face within frame
   - Keep face straight (head angles < 20°/15°)
   - Ensure single face visible
   - Tap "Capture Face"

4. **Verify Success**
   - Look for success message
   - Check Flutter console for: `✅ Face uploaded to backend successfully`
   - Check backend console for upload logs
   - Verify file exists in `backend/uploads/faces/`

5. **Verify Backend Storage**
   ```bash
   # In terminal:
   curl http://localhost:5001/api/face/check/sam@gmail.com
   
   # Expected response:
   # {"registered":true,"email":"sam@gmail.com","uploadedAt":"2024-12-24T..."}
   ```

### Test 2: Resident Face Verification from Backend

**Steps:**
1. **Login as Resident**
   - Email: Any registered resident
   - Password: Resident's password

2. **Scan Agent QR Code**
   - Tap "Scan QR Code"
   - Scan the agent's QR code (must be verified agent)
   - View agent details screen

3. **Verify Agent Face**
   - Tap "Verify Agent Face" button
   - Allow camera permissions if prompted
   - Ask agent to position face in frame
   - Tap "Verify Face"

4. **Check Backend Download**
   - Look for console log: `✅ Face downloaded from backend`
   - Verify temporary file created in `/agent_faces_backend/`
   - App should show loading indicator while downloading

5. **Verify Comparison Result**
   - **Match Score ≥ 70%**: Green checkmark, "Agent Verified Successfully"
   - **Match Score < 70%**: Red X, "Face does not match"
   - Details show: Agent name, email, match score

### Test 3: Offline Support

**Steps:**
1. **Register Face Online**
   - Complete Test 1 successfully

2. **Disconnect from Internet**
   - Turn off WiFi/Mobile data

3. **Register New Face**
   - Agent can still register face (saves locally)
   - Console shows: `⚠️ Face upload to backend failed`
   - Local storage still works

4. **Verify Face Offline**
   - Resident can verify if face was downloaded previously
   - App falls back to local storage

5. **Reconnect Internet**
   - Face should sync on next registration attempt

### Test 4: Multiple Device Sync

**Steps:**
1. **Device A (Agent Registration)**
   - Agent registers face on Device A
   - Face uploads to backend successfully

2. **Device B (Resident Verification)**
   - Resident on Device B scans agent QR
   - Taps "Verify Agent Face"
   - Face downloads from backend automatically
   - Comparison works across devices ✓

3. **Verify Cross-Device**
   - Face registered on one device
   - Verified on different device
   - Backend acts as central storage

## Expected Behavior

### Success Scenarios
✅ **Agent Registration**
- Camera captures face correctly
- ML Kit detects single face with proper angles
- Image saves locally
- Image uploads to backend (if online)
- Success dialog appears

✅ **Resident Verification (Match)**
- Agent face downloads from backend
- Live face captured successfully
- Match score ≥ 70%
- Green verification message
- Agent details displayed

✅ **Resident Verification (No Match)**
- Download successful
- Live face captured
- Match score < 70%
- Red warning message
- "Face does not match" error

### Error Scenarios
⚠️ **Face Not Registered**
- Backend returns 404 for GET /api/face/image/:email
- App shows: "Agent has not registered face"
- Verification cannot proceed

⚠️ **Network Error**
- Backend unreachable
- App falls back to local storage
- Shows warning if local also unavailable

⚠️ **Multiple Faces Detected**
- ML Kit detects more than one face
- Registration/verification fails
- Error: "Please ensure only one face in frame"

⚠️ **Poor Face Quality**
- Head angles exceed limits (Y > 20°, Z > 15°)
- Registration fails
- Error: "Please keep your head straight"

## Verification Checklist

Use this checklist to confirm everything works:

- [ ] Backend server running on port 5001
- [ ] Face routes loaded (check console on startup)
- [ ] Agent can register face successfully
- [ ] Face uploads to backend (check uploads/faces/ folder)
- [ ] `/api/face/check/:email` returns `registered: true`
- [ ] Resident can scan agent QR code
- [ ] Face downloads from backend during verification
- [ ] Console shows: `✅ Face downloaded from backend`
- [ ] Face comparison works correctly
- [ ] Match score displays properly (70% threshold)
- [ ] Cross-device verification works
- [ ] Offline mode falls back to local storage
- [ ] Error messages display for edge cases

## Backend Verification Commands

```bash
# Check if face is registered
curl http://localhost:5001/api/face/check/sam@gmail.com

# List uploaded face files
ls -la backend/uploads/faces/

# Delete a registered face
curl -X DELETE http://localhost:5001/api/face/delete/sam@gmail.com

# Check backend logs
# Look for:
# - "✅ Face uploaded successfully"
# - "✅ Face retrieved for: {email}"
# - Error messages for debugging
```

## Console Logs to Monitor

### Flutter App
```
✅ Face uploaded to backend successfully
✅ Face downloaded from backend
⚠️ Face upload to backend failed
⚠️ Failed to download face from backend
```

### Backend Server
```
Socket.IO service initialized
🚀 Server running on port 5001
✅ MongoDB connected successfully
# Face upload/download logs from face.routes.js
```

## Troubleshooting

### Issue: Face not uploading to backend
**Solution:**
- Check backend server is running: `lsof -i:5001`
- Verify network connectivity
- Check Flutter console for error messages
- Ensure `AppConstants.baseUrl` points to correct URL

### Issue: Face download fails during verification
**Solution:**
- Verify face was uploaded first (check `/api/face/check/:email`)
- Check backend uploads/faces/ folder for file
- Ensure resident has internet connection
- Check email matches exactly (case-sensitive)

### Issue: Match score always low
**Solution:**
- Ensure good lighting conditions
- Agent should face camera directly
- Remove glasses/hat if possible
- Verify same person in both images

### Issue: "Agent has not registered face" error
**Solution:**
- Agent must register face first
- Complete Test 1 before Test 2
- Check backend with: `curl http://localhost:5001/api/face/check/{email}`

## Security Notes

**Current Implementation:**
- Face images stored in `backend/uploads/faces/`
- No encryption at rest (development only)
- Simple Map() storage (not persisted to database)

**Production Recommendations:**
- Migrate face data to MongoDB
- Encrypt face images at rest
- Use face embeddings instead of full images
- Add authentication middleware to face routes
- Implement audit logging for verification attempts
- Add rate limiting to prevent abuse

## Next Steps

1. **Test Complete Flow**
   - Follow Test 1, 2, 3, 4 in order
   - Check all items in verification checklist
   - Document any issues found

2. **Database Migration**
   - Create FaceData model in MongoDB
   - Replace Map() with Mongoose queries
   - Add indexes on email field

3. **Security Enhancements**
   - Add JWT authentication to face routes
   - Implement file encryption
   - Add audit trail

4. **UI/UX Improvements**
   - Show progress during download
   - Add retry button for failed uploads
   - Display sync status on dashboard

## Contact

For issues or questions during testing:
- Check Flutter console logs
- Check backend terminal output
- Review this document's troubleshooting section
