@echo off
echo ========================================
echo Adding Windows Firewall Rule
echo ========================================
echo.
echo Allowing incoming connections on port 5001...
echo.

netsh advfirewall firewall delete rule name="SecureStep Backend Port 5001" 2>nul
netsh advfirewall firewall add rule name="SecureStep Backend Port 5001" dir=in action=allow protocol=TCP localport=5001

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ SUCCESS! Port 5001 is now open.
    echo.
    echo Your Computer IP: 10.156.78.17
    echo Backend URL: http://10.156.78.17:5001
    echo.
    echo Next Steps:
    echo 1. Make sure backend is running
    echo 2. Connect phone to SAME WiFi network
    echo 3. Hot restart Flutter app on phone (press R)
    echo 4. Try registering again!
) else (
    echo.
    echo ❌ ERROR: Could not add firewall rule
    echo.
    echo Please RIGHT-CLICK this file and select "Run as administrator"
)
echo.
pause
