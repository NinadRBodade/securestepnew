@echo off
echo ========================================
echo SecureStep - Allow Mobile Access
echo ========================================
echo.

echo Step 1: Checking current IP address...
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    set IP=!IP:~1!
    echo Your Computer IP: !IP!
)
echo.

echo Step 2: Adding Windows Firewall rule for port 5001...
echo.
netsh advfirewall firewall delete rule name="SecureStep Backend"
netsh advfirewall firewall add rule name="SecureStep Backend" dir=in action=allow protocol=TCP localport=5001
echo.

if %ERRORLEVEL% EQU 0 (
    echo ✅ SUCCESS! Firewall rule added.
    echo.
    echo ========================================
    echo Next Steps:
    echo ========================================
    echo 1. Make sure backend is running: npm start
    echo 2. Connect your phone to the SAME WiFi network
    echo 3. Update lib/utils/constants.dart with your IP
    echo 4. Test in browser: http://!IP!:5001
    echo 5. Rebuild Flutter app on phone
    echo ========================================
) else (
    echo ❌ ERROR: Failed to add firewall rule
    echo Please run this script as Administrator!
    echo Right-click and select "Run as administrator"
)
echo.
pause
