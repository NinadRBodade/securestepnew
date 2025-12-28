@echo off
echo Starting SecureStep Servers...
echo.

REM Start Backend API Server (Port 5001)
echo Starting Backend API Server on port 5001...
start "Backend API Server" cmd /k "cd /d %~dp0backend && npm start"

REM Wait 3 seconds
timeout /t 3 /nobreak >nul

REM Start Portal Server (Port 8080)
echo Starting Portal Server on port 8080...
start "Portal Server" cmd /k "cd /d %~dp0backend && node portal-server.js"

echo.
echo ========================================
echo Servers Started Successfully!
echo ========================================
echo.
echo Backend API Server: http://localhost:5001
echo Admin Portal: http://localhost:8080/admin_portal/index.html
echo Agent Portal: http://localhost:8080/agent_portal/index.html  
echo Police Portal: http://localhost:8080/police_portal/index.html
echo.
echo Close the server windows to stop the servers.
echo.
pause
