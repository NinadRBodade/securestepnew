require('dotenv').config();
console.log('✅ dotenv loaded');

const express = require('express');
console.log('✅ express loaded');

const app = express();
console.log('✅ app created');

app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
});
