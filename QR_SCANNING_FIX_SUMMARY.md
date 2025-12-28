# QR Code Scanning Fix - Complete Summary

## Problem Statement
**FormatException: Unexpected character `<!DOCTYPE html>`**

The Flutter app was receiving HTML instead of JSON when scanning QR codes. This happened because:
1. QR code contains **pure JSON data** (not URLs)
2. Flutter was calling the wrong backend endpoint or backend was returning HTML

## Root Cause Analysis

### QR Code Content
The agent QR codes contain:
```json
{
  "id": "agent@example.com",
  "name": "John Doe",
  "email": "agent@example.com",
  "company": "Security Corp",
  "verified": true,
  "score": 85,
  "issuedAt": "2025-12-29T10:30:00Z",
  "expiresAt": "2025-12-30T10:30:00Z",
  "signedHash": "abc123...",
  "signature": "abc123..."
}
```

**Key Point:** QR contains JSON, NOT a URL

### What Was Wrong
1. Backend had NO dedicated `/api/agents/verify-qr` endpoint
2. Flutter would fail or hit wrong route → Express fallback returned HTML
3. JSON parser tried to decode HTML → `FormatException`

## Solution Implemented

### ✅ Backend Changes

#### 1. Created New Verification Endpoint
**File:** `backend/src/routes/agent.routes.js`

```javascript
// Verify agent QR code (must come BEFORE /:email route)
router.post('/verify-qr', agentController.verifyQR);
```

**Critical:** Route is placed BEFORE `/:email` to avoid path conflicts

#### 2. Implemented Controller Method
**File:** `backend/src/controllers/agent.controller.js`

```javascript
exports.verifyQR = async (req, res) => {
  try {
    console.log('📱 POST /api/agents/verify-qr called');
    console.log('📦 Request body:', JSON.stringify(req.body));
    
    const qrData = req.body;
    
    if (!qrData || !qrData.id || !qrData.email) {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid QR code: missing required fields' 
      });
    }

    const agent = await Agent.findOne({ 
      $or: [
        { id: qrData.id },
        { email: qrData.email }
      ]
    });
    
    if (!agent) {
      return res.status(404).json({ 
        success: false,
        error: 'Agent not found in database' 
      });
    }

    // Return agent details as JSON ONLY (no HTML, no redirects)
    return res.status(200).json({
      success: true,
      agent: {
        id: agent.id,
        name: agent.name,
        email: agent.email,
        phone: agent.phone,
        company: agent.company,
        verified: agent.verified,
        score: agent.score || 0,
        documentsUploaded: agent.documentsUploaded || false,
        serviceType: agent.serviceType || 'General'
      }
    });
  } catch (error) {
    console.error('❌ Error in verifyQR:', error);
    return res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};
```

**Key Features:**
- ✅ Always returns JSON (never HTML)
- ✅ Validates required fields (id, email)
- ✅ Finds agent by ID or email
- ✅ Comprehensive error handling
- ✅ Debug logging for troubleshooting

### ✅ Frontend Changes

#### File: `lib/screens/resident/resident_scan_qr_screen.dart`

**1. QR Data Processing (Lines 66-120)**
```dart
Future<void> _processQRCode(String qrData) async {
  try {
    // Validate: Check for HTML
    if (qrData.trim().startsWith('<!DOCTYPE') || qrData.trim().startsWith('<html')) {
      _showErrorDialog('Invalid QR Code', 'This appears to be HTML...');
      return;
    }
    
    // Validate: Check for URL
    if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
      _showErrorDialog('Invalid QR Code', 'This is a URL, not agent data...');
      return;
    }
    
    // Parse JSON
    Map<String, dynamic> agentData;
    try {
      agentData = json.decode(qrData);  // ✅ Parse QR as JSON first
    } catch (e) {
      _showErrorDialog('Invalid Format', 'Could not read QR code data...');
      return;
    }
    
    // Validate required fields
    if (!agentData.containsKey('id') || !agentData.containsKey('email')) {
      _showErrorDialog('Invalid QR Code', 'Missing required information...');
      return;
    }
    
    // Proceed with verification
    _fetchAgentDetailsOnline(agentData);
  } catch (e) {
    // Handle error
  }
}
```

**2. API Call (Lines 176-220)**
```dart
Future<void> _fetchAgentDetailsOnline(Map<String, dynamic> qrData) async {
  try {
    print('🔍 Verifying agent QR with ID: ${qrData['id']}');
    print('🌐 API URL: ${AppConstants.baseUrl}/api/agents/verify-qr');
    print('📋 Scanned QR String: ${json.encode(qrData)}');  // ✅ Debug log
    
    // Send QR data to backend for verification
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/agents/verify-qr'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(qrData),  // ✅ Send entire QR data
    ).timeout(Duration(seconds: 10));

    // Check if response is HTML (BUG in backend)
    if (response.body.trim().startsWith('<!DOCTYPE') || 
        response.body.trim().startsWith('<html')) {
      print('❌ BACKEND BUG: Server returned HTML instead of JSON');
      _showErrorDialog(
        'Server Configuration Error',
        'Backend returned HTML instead of JSON. This is a backend bug.'
      );
      return;
    }

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'] ?? '';
      
      if (!contentType.contains('application/json')) {
        throw Exception('Server returned non-JSON content-type: $contentType');
      }

      final data = json.decode(response.body);
      
      if (data['success'] == true && data.containsKey('agent')) {
        // Navigate to result screen
        Navigator.pushReplacement(context, 
          MaterialPageRoute(builder: (_) => 
            AgentVerificationResultScreen(agentData: data['agent'])
          )
        );
      }
    } else if (response.statusCode == 404) {
      _showErrorDialog('Agent Not Found', 'No agent registered with this email.');
    }
  } catch (e) {
    // Handle errors
  }
}
```

**Key Features:**
- ✅ Parses QR as JSON FIRST (never treats as URL)
- ✅ Validates HTML/URL before processing
- ✅ Detects if backend returns HTML
- ✅ Debug logging for troubleshooting
- ✅ Content-Type validation
- ✅ Proper error messages for users

## Testing Steps

### 1. Test Backend Endpoint
```powershell
$body = @{
    id = 'swapnil12@gmail.com'
    name = 'Swapnil Jadhav'
    email = 'swapnil12@gmail.com'
    company = 'Tech Corp'
    verified = $true
    score = 85
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://10.156.78.17:5001/api/agents/verify-qr' `
    -Method POST `
    -Body $body `
    -ContentType 'application/json'
```

**Expected Response:**
```json
{
  "success": true,
  "agent": {
    "id": "swapnil12@gmail.com",
    "name": "Swapnil Jadhav",
    "email": "swapnil12@gmail.com",
    "company": "Tech Corp",
    "verified": true,
    "score": 85
  }
}
```

### 2. Test Flutter App
1. **Phone A**: Open Agent Dashboard → Display QR code
2. **Phone B**: Open Resident App → Tap "Scan Agent QR"
3. Point camera at Phone A's QR code
4. **Check Console Logs:**
   ```
   📷 RESIDENT QR SCAN:
   Length: 267
   Data: {"id":"swapnil12@gmail.com",...}
   
   🔍 Verifying agent QR with ID: swapnil12@gmail.com
   🌐 API URL: http://10.156.78.17:5001/api/agents/verify-qr
   📋 Scanned QR String: {"id":"swapnil12@gmail.com",...}
   
   📡 Status: 200
   📝 Response Body: {"success":true,"agent":{...}}
   ✅ Agent verified: Swapnil Jadhav
   ```

5. **Expected Result:**
   - Agent verification screen opens
   - Shows agent name, company, verified status, score
   - No FormatException errors

## Common Issues & Solutions

### Issue 1: "Cannot POST /api/agents/verify-qr"
**Cause:** Backend server not restarted after code changes  
**Solution:** Restart backend: `cd backend && npm start`

### Issue 2: Still getting HTML response
**Cause:** 
- Backend route order wrong
- Static file serving catching the route

**Solution:** 
- Ensure `/verify-qr` route is BEFORE `/:email` route
- Check `server.js` - API routes should be registered BEFORE static file serving

### Issue 3: "Agent not found"
**Cause:** Agent doesn't exist in database  
**Solution:** 
- Register agent first via `/api/agent/register`
- Or scan QR of an existing agent

### Issue 4: Network timeout
**Cause:** Backend not accessible from mobile device  
**Solution:** 
- Ensure backend is running: `http://10.156.78.17:5001/health`
- Check firewall settings
- Verify both devices on same WiFi network

## Architecture Notes

### Why This Approach Works

**Before (BROKEN):**
```
QR Scan → Try to fetch QR string as URL → Get HTML → FormatException
```

**After (FIXED):**
```
QR Scan → Parse JSON → Extract data → POST to /api/agents/verify-qr → Get JSON → Display
```

### Key Principles

1. **QR is Data, Not URL**
   - QR contains JSON data structure
   - Never treat QR content as a URL
   - Parse locally first, then send to backend

2. **Backend Must Return JSON**
   - Use `res.json()` always
   - Never `res.send()`, `res.sendFile()`, or `res.redirect()`
   - Set Content-Type: application/json

3. **Route Ordering Matters**
   - Specific routes (`/verify-qr`) before dynamic routes (`/:email`)
   - API routes before static file serving
   - Express processes routes in order

4. **Validation at Multiple Layers**
   - Frontend: Validate QR structure before API call
   - Backend: Validate request body before database query
   - Both: Check Content-Type headers

## Files Modified

### Backend
- ✅ `backend/src/routes/agent.routes.js` - Added verify-qr route
- ✅ `backend/src/controllers/agent.controller.js` - Added verifyQR method

### Frontend
- ✅ `lib/screens/resident/resident_scan_qr_screen.dart` - Complete rewrite
  - Fixed QR processing logic
  - Added HTML detection
  - Changed API endpoint
  - Added debug logging

### Test Files Created
- ✅ `backend/test-verify-qr.js` - Node.js test script for endpoint

## Next Steps

1. ✅ Backend restart completed with new routes
2. ⏳ Flutter app deploying to device
3. 📱 Test scanning flow end-to-end
4. 📊 Monitor logs for any issues

## Success Criteria

- [ ] QR code scans without errors
- [ ] No HTML responses from backend
- [ ] Agent profile displays correctly
- [ ] Console shows proper debug logs
- [ ] Works for both online and offline modes

---
**Status:** FIXES IMPLEMENTED - READY FOR TESTING
**Date:** December 29, 2025
