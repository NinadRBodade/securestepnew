#!/bin/bash

echo "🚀 Starting Society Safety App Development Environment"
echo "======================================================"
echo ""

# Start Backend
echo "📡 Starting Backend Server on port 5001..."
cd backend
node src/server.js &
BACKEND_PID=$!
echo "✅ Backend started with PID: $BACKEND_PID"
cd ..

# Wait for backend to initialize
sleep 2

# Check if backend is running
if lsof -i:5001 > /dev/null 2>&1; then
  echo "✅ Backend is running on http://localhost:5001"
else
  echo "❌ Backend failed to start"
  exit 1
fi

echo ""
echo "📱 Starting Flutter App..."
echo ""

# Start Flutter
flutter run

# Cleanup on exit
trap "kill $BACKEND_PID 2>/dev/null" EXIT
