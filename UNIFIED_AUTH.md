# Unified Registration & Login System

## ✅ What's Been Created:

### 1. **Registration Screen** (`register_screen.dart`)
- Single form for all roles
- Fields: Name, Email, Phone, Password, Role (dropdown)
- Connects to backend `/api/auth/register`
- Validates all inputs
- Automatically redirects to login after success

### 2. **Unified Login Screen** (`login_screen_unified.dart`)
- One login for all users
- Backend determines user role automatically
- Redirects to correct home screen based on role:
  - Agent → Agent Home
  - Resident → Resident Home
  - Guard → Guard Home
  - Admin → Admin Home
- Falls back to mock login if backend unavailable

### 3. **Backend Auth API** (Updated)
- **POST /api/auth/register** - Register new users
  - Accepts: name, email, password, phone, role
  - Returns: success message + user data
  
- **POST /api/auth/login** - Login existing users
  - Accepts: email, password
  - Returns: token + user data with role
  - Role determines which screen to show
  
- **GET /api/auth/users** - List all registered users (debug)

### 4. **Updated Navigation Flow**
```
Splash Screen (3 sec)
    ↓
Login Screen ← → Register Screen
    ↓
(After successful login, based on role)
    ↓
┌─────────┬──────────┬──────────┬─────────┐
│ Agent   │ Resident │  Guard   │  Admin  │
│  Home   │   Home   │   Home   │  Home   │
└─────────┴──────────┴──────────┴─────────┘
```

## 🎯 How to Test:

### Start Backend:
```bash
cd ~/Desktop/society_safety_app/backend
node src/server.js
```

### Test Registration Flow:
1. App opens → Splash screen
2. Wait 3 seconds → Login screen appears
3. Click "Register" button
4. Fill form:
   - Name: John Doe
   - Email: john@test.com
   - Phone: 1234567890
   - Password: test123
   - Role: Select from dropdown
5. Click "Register"
6. Success → Redirected to Login
7. Login with same credentials
8. Opens correct home screen based on role!

### Demo Credentials (still work):
- agent@demo.com / agent123
- resident@demo.com / resident123
- guard@demo.com / guard123
- admin@demo.com / admin123

## 📝 Next Steps:
When you're ready, we can add:
- Password reset functionality
- Email verification
- Profile picture upload
- Token storage (persistent login)
- Better error handling
- Database integration (MongoDB models)
