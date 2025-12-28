# 📧 Email Configuration Fix Guide

## Problem
Email sending is failing with connection timeout error.

## Quick Fix Options

### Option 1: Use Development Mode (FASTEST - For Testing)
The backend already supports dev mode that returns credentials in the response without sending email.

**No changes needed!** The system already detects if email is not configured and returns credentials directly.

---

### Option 2: Fix Gmail Configuration (RECOMMENDED for Production)

#### Step 1: Generate New Gmail App Password
1. Go to: https://myaccount.google.com/security
2. Make sure **2-Step Verification** is enabled
3. Go to: https://myaccount.google.com/apppasswords
4. Create a new App Password:
   - App: **Mail**
   - Device: **Windows Computer** (or custom name)
5. Google will generate a 16-character password (e.g., `abcd efgh ijkl mnop`)
6. **Copy this password** (remove spaces)

#### Step 2: Update .env File
Open `backend/.env` and update:
```env
EMAIL_USER=swapnilchidrawar46@gmail.com
EMAIL_PASSWORD=abcdefghijklmnop  # Replace with your new 16-char password (no spaces)
```

#### Step 3: Test Email
```bash
cd backend
node test-email.js
```

You should see: ✅ Email Configuration is WORKING!

---

### Option 3: Alternative - Use Mailtrap (For Development)
If Gmail continues to fail, use Mailtrap (free testing service):

1. Sign up at: https://mailtrap.io (free)
2. Get SMTP credentials from your inbox
3. Update `backend/src/utils/email.service.js`:
```javascript
const createTransporter = () => {
    return nodemailer.createTransport({
        host: 'sandbox.smtp.mailtrap.io',
        port: 2525,
        auth: {
            user: 'YOUR_MAILTRAP_USER',
            pass: 'YOUR_MAILTRAP_PASS'
        }
    });
};
```

---

## Network Issues?

If you're on a corporate network or using VPN:
- Port 587 might be blocked
- Try using your mobile hotspot
- Check Windows Firewall settings

---

## Current Status
✅ Backend is running
✅ MongoDB connected
✅ Development mode is active (credentials returned in response)
❌ Email sending disabled (but app still works!)

**For hackathon/demo purposes, development mode is perfectly fine!**
