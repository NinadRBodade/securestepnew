@echo off
echo ============================================
echo Gmail Setup for SecureStep Guard Credentials
echo ============================================
echo.
echo Follow these steps to enable email sending:
echo.
echo 1. Open: https://myaccount.google.com/security
echo 2. Enable 2-Step Verification (if not enabled)
echo 3. Go to: https://myaccount.google.com/apppasswords
echo 4. Create App Password:
echo    - App: Mail
echo    - Device: Other (type "SecureStep")
echo 5. Copy the 16-character password
echo.
echo Then update backend\.env file with:
echo    EMAIL_USER=your-email@gmail.com
echo    EMAIL_PASSWORD=xxxx xxxx xxxx xxxx (remove spaces)
echo.
echo ============================================
echo Opening Google Account Security page...
echo ============================================
start https://myaccount.google.com/security
pause
