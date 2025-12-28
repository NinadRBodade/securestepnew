# Face Recognition Feature

## Overview
The face recognition feature provides biometric verification for agents in the society safety app. It allows agents to register their face and residents to verify the agent's identity during visits.

## Features

### 1. Agent Face Registration
**Location:** Agent Home Screen → "Register Face" button

**Functionality:**
- Opens camera for face capture
- Uses ML Kit for face detection with quality validation
- Checks for proper face positioning (head angles < 20°/15°)
- Ensures single face in frame
- Saves face image securely in app storage
- File path: `{app_documents}/agent_faces/{email}.jpg`

**Quality Checks:**
- Head Euler Angle Y < 20°
- Head Euler Angle Z < 15°
- Only one face allowed
- Minimum face size: 0.15

**Usage:**
1. Agent taps "Register Face" on dashboard
2. Position face within the frame
3. Keep face straight (minimal head tilt)
4. Tap "Capture Face" button
5. Success message confirms registration

### 2. Resident Face Verification
**Location:** Resident Scan QR → Agent Details → "Verify Agent Face" button

**Functionality:**
- Opens camera for live face capture
- Compares captured face with registered agent face
- Calculates match score (0-100%)
- Success threshold: 70%
- Shows verification result with agent details

**Verification Process:**
1. Resident scans agent's QR code
2. Views agent details
3. Taps "Verify Agent Face"
4. Agent positions face in frame
5. Resident taps "Verify Face"
6. App shows match score and verification status

**Match Score Interpretation:**
- **70-100%**: ✓ Verified - Agent identity confirmed
- **0-69%**: ✗ Not Verified - Identity mismatch

## Technical Details

### Dependencies
```yaml
camera: ^0.10.5+5
google_mlkit_face_detection: ^0.10.0
path_provider: ^2.1.1
path: ^1.8.3
```

### ML Kit Configuration
- **Mode**: Accurate
- **Enable Classification**: Yes
- **Enable Landmarks**: Yes
- **Enable Tracking**: Yes
- **Min Face Size**: 0.15
- **Performance Mode**: Accurate

### Face Comparison Algorithm
The current implementation uses:
- Head angle comparison (Euler angles Y and Z)
- Face bounding box size comparison
- Landmark-based similarity

**Note**: This is a simplified implementation for demonstration. For production, consider using:
- TensorFlow Lite face recognition models
- FaceNet or similar embeddings
- Cloud-based face recognition APIs (Azure Face API, AWS Rekognition)

## File Structure

```
lib/screens/
├── agent/
│   ├── agent_home_screen.dart (updated with face registration button)
│   ├── agent_face_registration_screen.dart (new)
│   └── agent_qr_screen.dart (updated to include email in QR data)
├── resident/
│   ├── agent_verification_result_screen.dart (updated with verify face button)
│   └── resident_face_verification_screen.dart (new)
```

## Storage
- **Location**: Application documents directory
- **Path**: `{app_documents}/agent_faces/`
- **Filename Format**: `{email_replacing_@_with_at}.jpg`
- **Example**: `agent@company.com` → `agent_at_company.jpg`

## Permissions Required

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for face registration and verification</string>
```

## Security Considerations

1. **Face Data Storage**
   - Images stored locally on device
   - Not uploaded to any server
   - Cleared when app is uninstalled

2. **Privacy**
   - Only agent's registered face is stored
   - Resident verification images are not saved
   - No face data shared between users

3. **Production Recommendations**
   - Encrypt stored face images
   - Use secure cloud storage
   - Implement proper authentication
   - Add audit logging for verifications
   - Consider biometric template storage (not full images)

## Known Limitations

1. **Lighting Conditions**: Works best in good lighting
2. **Face Angles**: Requires near-frontal face view
3. **Accessories**: May have issues with glasses, masks, hats
4. **Match Accuracy**: Simplified algorithm - not production-grade
5. **Single User**: One face per agent email only

## Future Enhancements

1. **Multiple Face Photos**: Allow multiple angles/lighting conditions
2. **Liveness Detection**: Prevent photo spoofing
3. **Cloud Sync**: Backup face data to secure cloud storage
4. **Advanced ML Models**: Use dedicated face recognition models
5. **Audit Trail**: Log all verification attempts
6. **Re-registration**: Allow agents to update their face photo
7. **Admin Dashboard**: View verification statistics

## Testing

### Test Agent Registration
1. Login as Agent
2. Navigate to Agent Dashboard
3. Tap "Register Face"
4. Follow on-screen instructions
5. Verify success message

### Test Face Verification
1. Login as Resident
2. Scan agent QR code (must be registered)
3. Tap "Verify Agent Face"
4. Compare face with registered photo
5. Check verification result

## Troubleshooting

**Camera Not Working**
- Check permissions in device settings
- Restart app
- Verify camera is not being used by another app

**Registration Failed**
- Ensure good lighting
- Keep face straight (minimal tilt)
- Remove accessories (glasses, hat)
- Ensure only one face in frame

**Low Match Score**
- Verify correct agent
- Check lighting conditions
- Ensure face is clearly visible
- Agent should face camera directly

**Agent Not Registered Error**
- Agent must register face first
- Check agent email matches QR code
- Verify registration was successful

## Support

For technical issues or questions, please contact the development team.
