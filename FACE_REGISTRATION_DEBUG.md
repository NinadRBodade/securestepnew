# Face Registration Troubleshooting Guide

## Problem: Unable to Register Face

You're experiencing issues when trying to register agent faces. This guide will help identify and fix the issue.

## Fixes Applied ✅

### 1. Enhanced Error Logging
- Added detailed console output for each step
- Errors now show on screen (not silent)
- Step-by-step process tracking

### 2. Better Error Handling
- Local save errors now throw exceptions
- Backend upload errors now throw exceptions (not ignored)
- Detailed error messages with context

### 3. Debug Information
- Shows URL being called
- Shows email being registered
- Shows file paths
- Shows response status codes

## How to Debug

### Step 1: Hot Reload the App
```
Press 'r' in the Flutter terminal (where you ran `flutter run`)
```

### Step 2: Try Registering Face Again
1. Login as Agent
2. Go to Agent Dashboard
3. Click "Register Face"
4. Position your face and capture

### Step 3: Watch the Flutter Console

Look for this output sequence:

#### ✅ Success Flow:
```
✅ Face detected, saving locally...
💾 Saving face image locally...
   App directory: /data/user/0/com.example.app/app_flutter
   Creating agent_faces directory...
   Saving to: /data/.../agent_faces/agent_test_com.jpg
   ✅ Local save successful
✅ Local save complete, uploading to backend...
📤 Uploading face to backend...
   URL: http://localhost:5001/api/face/upload
   Email: agent@test.com
   Image path: /data/.../camera/image.jpg
   Sending request...
   Response status: 200
   ✅ Upload successful: {"success":true,"message":"Face image uploaded successfully"...}
✅ Face registration process complete
```

#### ❌ Error Patterns:

**Error 1: Local Save Failed**
```
❌ Local save failed: FileSystemException: Cannot create file
```
**Cause**: Permission issue or storage full
**Fix**: Check app permissions, ensure storage space available

**Error 2: Network Connection**
```
❌ Upload error: SocketException: Failed host lookup 'localhost'
```
**Cause**: Backend URL incorrect or not accessible
**Fix**: 
- Running on mobile device? Change to your PC's IP
- Update `lib/utils/constants.dart`:
  ```dart
  static const String baseUrl = 'http://192.168.1.XXX:5001';
  ```

**Error 3: Backend Not Running**
```
❌ Upload error: Connection refused
```
**Cause**: Backend server not running
**Fix**: 
```powershell
cd backend
npm start
```

**Error 4: Backend Error**
```
   Response status: 400
   ❌ Upload failed: {"error":"Email and role are required"}
```
**Cause**: Missing required fields
**Fix**: Already fixed in code - should not occur

**Error 5: Timeout**
```
❌ Upload error: TimeoutException after 30 seconds
```
**Cause**: Slow network or large file
**Fix**: Check network connection, reduce camera resolution

## Quick Checks

### 1. Backend Server Running?
```powershell
# In PowerShell:
Invoke-RestMethod -Uri "http://localhost:5001/api/face/all"
```
Expected: `{"success":true,"count":0,"data":[]}`

### 2. Mobile App Using Correct URL?
Check `lib/utils/constants.dart`:
- ✅ Chrome/Web: `http://localhost:5001`
- ✅ Android Emulator: `http://10.0.2.2:5001`
- ✅ Real Device: `http://YOUR_PC_IP:5001`

### 3. Camera Permissions?
- Android: Check app permissions in settings
- Chrome: Allow camera access when prompted

## Testing Face Upload Manually

### Using PowerShell (Test Backend):
```powershell
# Create a test image file
$imagePath = "C:\path\to\test_image.jpg"

# Upload to backend
$uri = "http://localhost:5001/api/face/upload"
$form = @{
    email = "test@test.com"
    role = "agent"
    faceImage = Get-Item $imagePath
}
Invoke-RestMethod -Uri $uri -Method POST -Form $form
```

Expected response:
```json
{
  "success": true,
  "message": "Face image uploaded successfully",
  "data": {
    "email": "test@test.com",
    "filename": "test_test_com_1703765432123.jpg",
    "uploadedAt": "2025-12-27T..."
  }
}
```

## Common Solutions

### Issue: "Error verifying face" when scanning
**Root Cause**: No faces in backend to compare against
**Solution**: Register agent face first (this guide)

### Issue: App shows generic error
**Root Cause**: Error logging was too quiet
**Solution**: Already fixed - now shows detailed errors

### Issue: Backend returns 404
**Root Cause**: Wrong backend URL or server not running
**Solution**: 
1. Check backend is running: `npm start`
2. Check URL in constants.dart
3. For mobile devices, use PC's IP address

### Issue: Image too large
**Root Cause**: High resolution camera
**Solution**: Already limited to 5MB in backend

## Verification Steps

After successful registration:

### 1. Check Backend Database
```powershell
cd backend
.\test-face-api.ps1
```
Expected output:
```
✅ Backend has 1 registered face(s):
   📸 agent@test.com - agent
```

### 2. Check Local Storage (Optional)
Flutter will also save locally:
```
App Documents Directory:
  └── agent_faces/
      └── agent_test_com.jpg
```

### 3. Test Face Verification
1. Logout from agent
2. Login as resident
3. Try "Scan Agent Face"
4. Should download face from backend and verify

## Still Not Working?

### Collect This Information:

1. **Flutter Console Output** (full log from registration attempt)
2. **Backend Console Output** (server logs)
3. **Device Type**: Chrome? Android Emulator? Real device?
4. **Backend URL** from constants.dart
5. **Error Message** displayed on screen

### Check Backend Logs:
Look in the terminal where `npm start` is running for:
```
POST /api/face/upload
✅ Face uploaded to MongoDB for: agent@test.com
```

### Network Testing:
From mobile device browser, visit:
```
http://YOUR_PC_IP:5001/api/face/all
```
Should show JSON response (not error)

## Summary

**What Changed**:
- ✅ Added extensive logging
- ✅ Errors now visible and descriptive
- ✅ Backend upload failures now caught
- ✅ Step-by-step progress tracking

**Next Steps**:
1. Hot reload app (`r`)
2. Try registration again
3. Copy any error messages
4. Check Flutter console for detailed logs
5. Verify backend received the upload

---

**Updated**: December 27, 2025
**Version**: 1.2.0 (Enhanced Error Handling)
