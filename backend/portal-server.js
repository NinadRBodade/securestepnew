const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 8080;

// Enable CORS
app.use(cors());

// Serve static files from admin_portal directory
app.use('/admin_portal', express.static(path.join(__dirname, '../admin_portal')));

// Serve static files from agent_portal directory
app.use('/agent_portal', express.static(path.join(__dirname, '../agent_portal')));

// Serve static files from police_portal directory
app.use('/police_portal', express.static(path.join(__dirname, '../police_portal')));

// Serve uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Root redirect
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>SecureStep Portals</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
          }
          .container {
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
          }
          h1 {
            color: #1a202c;
            text-align: center;
            margin-bottom: 30px;
          }
          .portal-link {
            display: block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            margin: 15px 0;
            text-decoration: none;
            border-radius: 8px;
            font-size: 18px;
            font-weight: bold;
            text-align: center;
            transition: transform 0.2s, box-shadow 0.2s;
          }
          .portal-link:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
          }
          .portal-link .icon {
            font-size: 24px;
            margin-right: 10px;
          }
          .info {
            background: #f7fafc;
            padding: 15px;
            border-radius: 8px;
            margin-top: 30px;
            color: #4a5568;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🏢 SecureStep Management Portals</h1>
          <a href="/admin_portal/index.html" class="portal-link">
            <span class="icon">👨‍💼</span>
            Admin Dashboard
          </a>
          <a href="/agent_portal/index.html" class="portal-link">
            <span class="icon">👮</span>
            Agent Verification Portal
          </a>
          <a href="/police_portal/index.html" class="portal-link">
            <span class="icon">🚓</span>
            Police Emergency Dashboard
          </a>
          <div class="info">
            <strong>ℹ️ Info:</strong> Make sure the backend server is running on port 5001.
            <br><br>
            <strong>Admin Portal:</strong> Manage societies, guards, and agents
            <br>
            <strong>Agent Portal:</strong> Verify and manage delivery agents
            <br>
            <strong>Police Portal:</strong> Monitor SOS alerts and emergencies
          </div>
        </div>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║                                                        ║
║   🌐 SecureStep Web Portals Server                    ║
║                                                        ║
║   Agent Portal:  http://localhost:${PORT}/agent_portal/    ║
║   Police Portal: http://localhost:${PORT}/police_portal/   ║
║                                                        ║
║   Server running on port ${PORT}                           ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
  `);
});
