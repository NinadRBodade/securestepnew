// Test SOS Endpoint
const http = require('http');

const options = {
  hostname: '127.0.0.1',
  port: 5001,
  path: '/api/sos',
  method: 'GET',
  headers: {
    'Content-Type': 'application/json'
  }
};

console.log('🧪 Testing SOS API endpoint...');
console.log(`📡 URL: http://${options.hostname}:${options.port}${options.path}\n`);

const req = http.request(options, (res) => {
  let data = '';

  console.log(`✅ Status Code: ${res.statusCode}`);
  console.log(`📋 Headers:`, res.headers);

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    try {
      const jsonData = JSON.parse(data);
      console.log('\n📊 Response Data:');
      console.log(JSON.stringify(jsonData, null, 2));
      
      if (jsonData.data && jsonData.data.events) {
        console.log(`\n🚨 Total SOS Alerts: ${jsonData.data.events.length}`);
      } else if (Array.isArray(jsonData)) {
        console.log(`\n🚨 Total SOS Alerts: ${jsonData.length}`);
      } else {
        console.log('\n⚠️ Unexpected response format');
      }
    } catch (error) {
      console.error('❌ Error parsing JSON:', error.message);
      console.log('Raw response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request failed:', error.message);
  console.log('\n💡 Troubleshooting:');
  console.log('1. Make sure the backend server is running on port 5001');
  console.log('2. Check if MongoDB is connected');
  console.log('3. Verify firewall settings');
});

req.end();
