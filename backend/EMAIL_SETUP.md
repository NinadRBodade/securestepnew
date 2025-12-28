# Guard Credential Email Setup Guide

## Overview
This system sends guard login credentials via email when a guard requests access through the mobile app.

## Email Service Configuration

### Using Gmail (Recommended for Testing)

1. **Enable 2-Step Verification**
   - Go to your Google Account: https://myaccount.google.com/
   - Navigate to Security → 2-Step Verification
   - Enable 2-Step Verification if not already enabled

2. **Generate App Password**
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" as the app
   - Select "Other" as the device and name it "SecureStep Backend"
   - Click "Generate"
   - Copy the 16-character app password

3. **Update .env File**
   ```env
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASSWORD=xxxx-xxxx-xxxx-xxxx
   ```
   Replace `your-email@gmail.com` with your Gmail address and the password with the generated app password (no spaces).

### Using Other Email Services

#### SendGrid
```env
EMAIL_SERVICE=sendgrid
SENDGRID_API_KEY=your-sendgrid-api-key
EMAIL_USER=noreply@yourdomain.com
```

#### AWS SES
```env
EMAIL_SERVICE=ses
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
EMAIL_USER=noreply@yourdomain.com
```

#### Outlook/Office365
```env
EMAIL_USER=your-email@outlook.com
EMAIL_PASSWORD=your-password
```
Update `email.service.js`:
```javascript
service: 'outlook'
```

## Flow Explanation

### Admin Creates Guard
1. Admin logs into Admin Web Portal
2. Admin creates a new guard account with:
   - Name
   - Email
   - Phone (optional)
   - Society ID
3. System automatically generates a random password
4. Both hashed password and plain text password (tempPassword) are saved to MongoDB
5. Guard data is saved in the `Guard` collection

### Guard Requests Credentials
1. Guard opens mobile app
2. Guard selects "Request Credentials" 
3. Guard enters their registered email
4. Frontend calls: `POST /api/auth/guard/request-credentials`
5. Backend:
   - Checks if email exists in Guard collection
   - Verifies guard account is active
   - Retrieves guard's tempPassword
   - Sends email with:
     * Email address
     * Password
     * Society name
     * Society ID
6. Guard receives email with credentials
7. Frontend shows success message and redirects to login
8. Guard logs in using received credentials

## API Endpoint

### Request Guard Credentials
```
POST /api/auth/guard/request-credentials
```

**Request Body:**
```json
{
  "email": "guard@example.com"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Your login credentials have been sent to your email address. Please check your inbox."
}
```

**Error Responses:**

Guard Not Found (404):
```json
{
  "success": false,
  "message": "This email is not registered as a guard. Please contact your society admin."
}
```

Guard Inactive (403):
```json
{
  "success": false,
  "message": "Your guard account has been deactivated. Please contact your society admin."
}
```

Email Sending Failed (500):
```json
{
  "success": false,
  "message": "Failed to send email. Please contact your society admin or try again later."
}
```

## Testing

### 1. Test Email Configuration
Add this to your server startup:
```javascript
const { testEmailConfig } = require('./utils/email.service');
testEmailConfig();
```

### 2. Create Test Guard via Admin Portal
- Login to Admin Portal: http://localhost:8080/admin_portal/
- Create a guard with your test email
- Note the auto-generated password from console

### 3. Test Credential Request
Using curl:
```bash
curl -X POST http://localhost:5001/api/auth/guard/request-credentials \
  -H "Content-Type: application/json" \
  -d '{"email":"guard@example.com"}'
```

Using Postman:
- Method: POST
- URL: `http://localhost:5001/api/auth/guard/request-credentials`
- Headers: `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "email": "guard@example.com"
}
```

### 4. Test from Mobile App
- Open guard access request screen
- Enter registered email
- Check email inbox for credentials

## Troubleshooting

### Email Not Sending

**Check 1: Email Configuration**
```javascript
// In server.js or add temporary test
const { testEmailConfig } = require('./utils/email.service');
testEmailConfig();
```

**Check 2: Gmail Security**
- Ensure 2-Step Verification is enabled
- Ensure App Password is generated (not regular password)
- Check "Less secure app access" is OFF (use App Password instead)

**Check 3: Backend Logs**
```bash
# Check terminal for errors
✅ Guard credentials email sent: <messageId>
# OR
❌ Failed to send guard credentials email: <error>
```

**Check 4: Guard Data**
```javascript
// Check if tempPassword exists
db.guards.findOne({ email: "guard@example.com" })
// Should return: { tempPassword: "abc12345", ... }
```

### Common Errors

1. **"Invalid login: 535-5.7.8 Username and Password not accepted"**
   - Solution: Use App Password, not regular Gmail password

2. **"Connection timeout"**
   - Solution: Check firewall/antivirus blocking port 587 or 465

3. **"Password information not available"**
   - Solution: Guard was created before tempPassword feature. Admin needs to recreate guard or manually set tempPassword in database.

4. **"Guard not found"**
   - Solution: Admin has not created this guard account yet

## Security Notes

1. **tempPassword Storage**: The plain text password is stored temporarily to allow email delivery. In a production environment with a proper password reset flow, you may want to:
   - Generate a one-time reset token instead
   - Send a password reset link rather than the actual password
   - Clear tempPassword after first login

2. **Email Security**: 
   - Never commit .env files with real credentials
   - Use App Passwords, not regular passwords
   - Consider using dedicated email services (SendGrid, AWS SES) for production

3. **Transport Security**:
   - Email is sent over TLS/SSL
   - Consider end-to-end encryption for highly sensitive environments

## Production Recommendations

1. **Use Professional Email Service**
   - SendGrid, AWS SES, Mailgun, or similar
   - Better deliverability and monitoring
   - Higher sending limits

2. **Implement Password Reset Flow**
   - Send reset link instead of password
   - Use time-limited tokens
   - Clear tempPassword after first successful login

3. **Add Email Templates**
   - Store templates in database
   - Support multiple languages
   - Customize branding per society

4. **Monitor Email Delivery**
   - Log all email attempts
   - Track delivery status
   - Alert on failures

## File Structure

```
backend/
├── src/
│   ├── controllers/
│   │   └── guard.auth.controller.js    # Handles credential requests
│   ├── models/
│   │   └── Guard.js                    # Guard schema with tempPassword
│   ├── routes/
│   │   └── auth.routes.js              # Route: /api/auth/guard/request-credentials
│   └── utils/
│       └── email.service.js            # Email sending logic
├── .env                                 # Email configuration
└── EMAIL_SETUP.md                      # This file
```

## Support

For issues or questions:
1. Check backend console logs
2. Verify .env configuration
3. Test email configuration with `testEmailConfig()`
4. Ensure MongoDB contains guard with tempPassword
