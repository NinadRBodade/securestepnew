#!/bin/bash
# Backend startup script

cd "$(dirname "$0")"

echo "🚀 Starting Society Safety Backend..."
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install
fi

# Start the server
echo "✨ Starting server on port 5001..."
npm run dev
