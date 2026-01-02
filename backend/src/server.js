console.log('1. Loading dotenv...');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

console.log('2. Loading express...');
const express = require('express');
const http = require('http');
const cors = require('cors');

console.log('3. Loading database config...');
const connectDB = require('./config/database');

console.log('4. Loading socket config...');
const initSocket = require('./config/socket');

console.log('5. Loading routes...');
// Routes
const authRoutes = require('./routes/auth.routes');
const agentRoutes = require('./routes/agent.routes');
const residentRoutes = require('./routes/resident.routes');
const guardRoutes = require('./routes/guard.routes');
const adminRoutes = require('./routes/admin.routes');
const societyRoutes = require('./routes/society.routes');
const visitRoutes = require('./routes/visit.routes');
const sosRoutes = require('./routes/sos.routes');
const blockchainRoutes = require('./routes/blockchain.routes');
const faceRoutes = require('./routes/face.routes');
const complaintRoutes = require('./routes/complaint.routes');
const adminGuardRoutes = require('./routes/admin.guard.routes');
const documentVerificationRoutes = require('./routes/documentVerification.routes');
const verifyRoutes = require('./routes/verify.routes');

// Middleware
const errorMiddleware = require('./middleware/error.middleware');

const app = express();
const server = http.createServer(app);

console.log('🚀 Starting Society Safety Backend...');

// Connect MongoDB
connectDB();

// Global middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));
app.use(express.json());

// Root route
app.get('/', (req, res) => {
  res.json({
    name: 'Society Safety Backend',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      health: '/health',
      api: '/api/*'
    }
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Backend running' });
});

// API routes - QR verification MUST be first (most specific route)
app.use('/api', verifyRoutes); // Handles /api/verify-agent
app.use('/api/auth', authRoutes);
app.use('/api/agent', agentRoutes);
app.use('/api/agents', agentRoutes); // Alternative path
app.use('/api/residents', residentRoutes);
app.use('/api/guards', guardRoutes); // Guard authenticated routes (QR scanning)
app.use('/api/admin', adminRoutes);
app.use('/api/society', societyRoutes);
app.use('/api/societies', societyRoutes); // Admin portal path
app.use('/api/admin/guards', adminGuardRoutes); // Admin guard management
app.use('/api/visits', visitRoutes);
app.use('/api/sos', sosRoutes);
app.use('/api/blockchain', blockchainRoutes);
app.use('/api/face', faceRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/verification', documentVerificationRoutes);

// Error handler (last)
app.use(errorMiddleware);

// Socket.IO
const { Server } = require('socket.io');
const io = new Server(server, {
  cors: { origin: '*' }
});
initSocket(io);

// Make io accessible to routes
app.set('io', io);

// Start server
const PORT = process.env.PORT || 5001;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Mobile/Police Portal: http://192.168.1.59:${PORT}`);
  console.log(`💻 Local: http://localhost:${PORT}`);
});