@echo off
echo Starting SecureStep Servers...
echo.

cd /d "%~dp0backend"

echo Starting Backend API Server (Port 5001)...
start "Backend Server" cmd /k "npm start"

timeout /t 3 /nobreak >nul

echo Starting Web Portals Server (Port 8080)...
start "Portal Server" cmd /k "node portal-server.js"

timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo Servers Started Successfully!
echo ========================================
echo.
echo Backend API:     http://localhost:5001
echo Agent Portal:    http://localhost:8080/agent_portal/
echo Police Portal:   http://localhost:8080/police_portal/
echo.
echo Opening Agent Portal in Chrome...
timeout /t 3 /nobreak >nul

start chrome "http://localhost:8080/agent_portal/"

echo.
echo Press any key to stop all servers...
pause >nul

taskkill /FI "WindowTitle eq Backend Server*" /T /F
taskkill /FI "WindowTitle eq Portal Server*" /T /F

echo.
echo All servers stopped.
pause
