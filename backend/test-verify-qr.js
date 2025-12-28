// Test script for verify-qr endpoint
const http = require('http');

const testData = JSON.stringify({
  id: 'swapnil12@gmail.com',
  name: 'Swapnil Jadhav',
  email: 'swapnil12@gmail.com',
  company: 'Tech Corp',
  verified: true,
  score: 85,
  issuedAt: new Date().toISOString(),
  expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
});

const options = {
  hostname: '10.156.78.17',
  port: 5001,
  path: '/api/agents/verify-qr',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Content-Length': Buffer.byteLength(testData)
  }
};

console.log('🧪 Testing POST /api/agents/verify-qr');
console.log('📤 Request Body:', testData);
console.log('');

const req = http.request(options, (res) => {
  console.log(`📡 Status Code: ${res.statusCode}`);
  console.log(`📋 Headers:`, res.headers);
  console.log('');

  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('📥 Response Body:');
    console.log(data);
    console.log('');

    // Check if response is JSON
    if (data.trim().startsWith('{')) {
      try {
        const parsed = JSON.parse(data);
        console.log('✅ Response is valid JSON');
        console.log('📊 Parsed Data:', JSON.stringify(parsed, null, 2));
      } catch (e) {
        console.error('❌ Failed to parse JSON:', e.message);
      }
    } else if (data.trim().startsWith('<!DOCTYPE') || data.trim().startsWith('<html')) {
      console.error('❌ ERROR: Backend returned HTML instead of JSON!');
      console.error('This is the bug causing FormatException in Flutter');
    } else {
      console.error('❌ Unexpected response format');
    }
  });
});

req.on('error', (e) => {
  console.error('❌ Request error:', e.message);
});

req.write(testData);
req.end();
