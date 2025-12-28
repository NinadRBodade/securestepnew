# Integration Guide - Adding Agent Verification Features

## Quick Start

### 1. Add Navigation Buttons to Existing Screens

#### For Agent Home Screen
Add these buttons to show document upload and profile:

```dart
// In agent_home_screen.dart

// Add to your screen
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentDocumentUploadScreen(
          agentId: 'LOGGED_IN_AGENT_ID',  // Get from login
          agentName: 'Agent Name',
          agentEmail: 'agent@email.com',
          agentPhone: '1234567890',
        ),
      ),
    );
  },
  icon: Icon(Icons.upload_file),
  label: Text('Upload Documents'),
),

ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentProfileScreen(
          agentId: 'LOGGED_IN_AGENT_ID',
        ),
      ),
    );
  },
  icon: Icon(Icons.person),
  label: Text('My Profile'),
),
```

#### For Admin Home Screen
Add verification dashboard button:

```dart
// In admin_home_screen.dart

ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminVerificationDashboard(
          adminId: 'LOGGED_IN_ADMIN_ID',  // Get from login
        ),
      ),
    );
  },
  icon: Icon(Icons.verified_user),
  label: Text('Verify Agents'),
),
```

#### For Resident Home Screen
Add QR scanner button:

```dart
// In resident_home_screen.dart

ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResidentQRScannerScreen(),
      ),
    );
  },
  icon: Icon(Icons.qr_code_scanner),
  label: Text('Scan Agent QR'),
),
```

### 2. Add Required Imports

Add these to the top of your home screen files:

```dart
// For Agent Home
import 'package:society_safety_app/screens/agent/agent_document_upload_screen.dart';
import 'package:society_safety_app/screens/agent/agent_profile_screen.dart';

// For Admin Home
import 'package:society_safety_app/screens/admin/admin_verification_dashboard.dart';

// For Resident Home
import 'package:society_safety_app/screens/resident/qr_scanner_screen.dart';
```

### 3. Update Agent Model (if using)

If you have an AgentModel class, add these fields:

```dart
class AgentModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final double score;              // 0.0 to 5.0
  final String? qrCode;            // Base64 data URL
  final DateTime? verifiedAt;
  final DateTime? submittedAt;

  // ... constructor and methods
}
```

### 4. Example: Complete Agent Home Screen Integration

```dart
import 'package:flutter/material.dart';
import 'agent_document_upload_screen.dart';
import 'agent_profile_screen.dart';

class AgentHomeScreen extends StatelessWidget {
  final String agentId;
  final String agentName;
  final String agentEmail;
  final String agentPhone;

  const AgentHomeScreen({
    Key? key,
    required this.agentId,
    required this.agentName,
    required this.agentEmail,
    required this.agentPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agent Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $agentName!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            
            // Document Upload Card
            Card(
              child: ListTile(
                leading: Icon(Icons.upload_file, size: 40, color: Colors.blue),
                title: Text('Upload Documents'),
                subtitle: Text('Submit verification documents'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgentDocumentUploadScreen(
                        agentId: agentId,
                        agentName: agentName,
                        agentEmail: agentEmail,
                        agentPhone: agentPhone,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 15),
            
            // Profile Card
            Card(
              child: ListTile(
                leading: Icon(Icons.person, size: 40, color: Colors.green),
                title: Text('My Profile'),
                subtitle: Text('View verification status & QR code'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgentProfileScreen(
                        agentId: agentId,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Add your other agent features here
          ],
        ),
      ),
    );
  }
}
```

### 5. Testing Workflow

**Step 1: Register as Agent**
```
1. Open app
2. Click "Register"
3. Select Role: "Agent"
4. Fill details → Register
5. Login
```

**Step 2: Upload Documents**
```
1. Click "Upload Documents"
2. Select ID Proof (PDF/Image)
3. Take Photo
4. Upload Certificate
5. Submit
```

**Step 3: Admin Verification**
```
1. Logout
2. Login as Admin
3. Click "Verify Agents"
4. View pending request
5. Click "Approve"
6. Set score (e.g., 4.5)
7. Confirm
```

**Step 4: Agent Gets QR Code**
```
1. Logout
2. Login as Agent
3. Click "My Profile"
4. See "Verified" status
5. See QR code displayed
6. See your rating (4.5 stars)
```

**Step 5: Resident Scans**
```
1. Logout
2. Login as Resident
3. Click "Scan Agent QR"
4. Point camera at QR code
5. View agent details
```

### 6. Backend Must Be Running

```bash
# Terminal 1: Start Backend
cd backend
node src/server.js

# Terminal 2: Start Flutter
flutter run
```

### 7. Common Issues & Solutions

**Issue: "Cannot upload files"**
- Solution: Check backend is running on port 5001
- Solution: Check Constants.baseUrl in lib/utils/constants.dart

**Issue: "QR scanner not working"**
- Solution: Grant camera permissions in emulator
- Solution: Check mobile_scanner package is installed

**Issue: "Agent not found"**
- Solution: Make sure agent ID matches between registration and profile

**Issue: "Documents not uploading"**
- Solution: Check uploads folder exists: `mkdir -p backend/uploads`
- Solution: Check file permissions

### 8. Next Features to Add (Optional)

1. **Push Notifications**
   - Notify agent when verified/rejected
   - Notify admin when new agent registers

2. **Document Preview**
   - Admin can view uploaded documents before approving

3. **Expiry Tracking**
   - Auto-reject if documents expire

4. **Batch Operations**
   - Admin can approve/reject multiple agents

5. **Statistics Dashboard**
   - Show total verified agents
   - Show average score
   - Show pending count

---

## Quick Reference: File Locations

### Backend
- Agent Routes: `/backend/src/routes/agent.routes.js`
- QR Service: `/backend/src/services/qr.service.js`
- Upload Config: `/backend/src/config/multer.config.js`

### Frontend
- Document Upload: `/lib/screens/agent/agent_document_upload_screen.dart`
- Admin Dashboard: `/lib/screens/admin/admin_verification_dashboard.dart`
- Agent Profile: `/lib/screens/agent/agent_profile_screen.dart`
- QR Scanner: `/lib/screens/resident/qr_scanner_screen.dart`

### API Base URL
```dart
// In lib/utils/constants.dart
class Constants {
  static const String baseUrl = 'http://localhost:5001';  // Adjust for your setup
}
```

---

**Status:** Ready to integrate! 🚀
