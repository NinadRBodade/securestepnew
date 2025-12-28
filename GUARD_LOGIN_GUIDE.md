# Guard Login Flow - Testing Guide

## Overview
Security Guards can now login to the app using their email or phone number. Guard accounts are created by Admin only (no self-registration).

## Flow Implementation

### 1. Role Selection Screen ("Who are you?")
- User selects **"Guard"** card
- Clicks **"Continue"** button
- Navigates to **Guard Login Screen**

### 2. Guard Login Screen
**Fields:**
- Email or Phone Number (single input field)
- Password
- Login button

**Features:**
- ✅ Accepts either email OR phone number
- ✅ Validates input based on type (email format or digits only for phone)
- ✅ No registration option (guards are admin-created)
- ✅ Role verification (ensures user is actually a guard)
- ✅ Clear error messages
- ✅ Info message: "Guard accounts are created by Admin only"

### 3. Authentication Logic
**Backend Changes:**
- Updated `/api/auth/login` endpoint to support login by phone
- Updated validation middleware to accept `email` OR `phone` parameter
- Login payload: `{ email: "..." }` OR `{ phone: "+911234567890" }`

**Frontend:**
- Auto-detects if input is email (contains @) or phone number
- Sends appropriate field to backend
- Verifies role is 'guard' before allowing login
- Shows error if non-guard tries to use this screen

### 4. After Successful Login
- Navigates to **Guard Home Screen** (already implemented)
- Dashboard shows: QR Scanner, Active Agents, Entry Logs, SOS Alerts

## Testing Instructions

### Prerequisites
1. Backend server running: `cd backend && npm start`
2. MongoDB running with guard user created by admin
3. Flutter app running: `flutter run -d chrome`

### Test Scenarios

#### Scenario 1: Login with Email
1. Open app → "Who are you?" screen
2. Select "Guard" → Click Continue
3. Enter email: `guard1@society.com`
4. Enter password: (guard's password)
5. Click Login
6. ✅ Should navigate to Guard Dashboard

#### Scenario 2: Login with Phone
1. Open app → "Who are you?" screen
2. Select "Guard" → Click Continue
3. Enter phone: `9876543210` (without country code)
4. Enter password: (guard's password)
5. Click Login
6. ✅ Should navigate to Guard Dashboard

#### Scenario 3: Invalid Credentials
1. Enter wrong email/phone or password
2. Click Login
3. ✅ Should show error: "Invalid credentials"

#### Scenario 4: Non-Guard User Attempt
1. Enter email of a resident/agent
2. Enter their password
3. Click Login
4. ✅ Should show error: "This login is only for Security Guards"

#### Scenario 5: Validation Errors
- Empty fields → "Email or phone number is required"
- Invalid email format → "Please enter a valid email address"
- Phone with letters → "Phone number should contain only digits"
- Short password → "Password must be at least 6 characters"

## Creating Test Guard Account

### Via MongoDB Direct Insert
```javascript
// Connect to MongoDB
use securestep

// Create guard user
db.users.insertOne({
  name: "John Doe",
  email: "guard1@society.com",
  password: "$2b$10$...", // bcrypt hashed password
  role: "guard",
  phone: "+919876543210",
  societyId: "SOC001",
  flatNumber: "Security Office",
  createdAt: new Date()
})
```

### Via Admin Portal (Recommended)
1. Login to Admin portal
2. Navigate to "Guards" section
3. Click "Add New Guard"
4. Fill details: Name, Email, Phone, Society
5. Set password
6. Save

## Files Modified

### Frontend (Flutter)
- ✅ `lib/screens/guard/guard_login_screen.dart` - NEW dedicated guard login UI
- ✅ `lib/screens/role_selection_screen.dart` - Updated guard navigation

### Backend (Node.js)
- ✅ `backend/src/routes/auth.routes.js` - Support login by phone
- ✅ `backend/src/middleware/validation.middleware.js` - Accept email OR phone

## API Endpoint

### POST /api/auth/login

**Request (Email):**
```json
{
  "email": "guard1@society.com",
  "password": "Guard@123"
}
```

**Request (Phone):**
```json
{
  "phone": "+919876543210",
  "password": "Guard@123"
}
```

**Success Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "64f7a8b9c1d2e3f4a5b6c7d8",
    "name": "John Doe",
    "email": "guard1@society.com",
    "role": "guard",
    "phone": "+919876543210",
    "societyId": "SOC001",
    "flatNumber": "Security Office"
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

## Security Features
- ✅ Password encrypted with bcrypt
- ✅ JWT token-based authentication
- ✅ Role verification (prevents non-guards from accessing)
- ✅ No registration endpoint for guards
- ✅ Input validation on both frontend and backend
- ✅ Sanitized inputs to prevent injection

## Next Steps (Optional Enhancements)
- [ ] Add "Forgot Password" for guards
- [ ] Add biometric login option
- [ ] Add session timeout
- [ ] Add login attempt limiting
- [ ] Add two-factor authentication
