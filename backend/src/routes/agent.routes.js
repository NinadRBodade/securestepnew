const express = require('express');
const router = express.Router();
const upload = require('../config/multer.config');
const agentController = require('../controllers/agent.controller');
const Agent = require('../models/Agent');

// Agent registration with documents
router.post('/register', upload.fields([
  { name: 'idProof', maxCount: 1 },
  { name: 'photo', maxCount: 1 },
  { name: 'certificate', maxCount: 1 }
]), agentController.registerAgent);

// Verify agent QR code (must come BEFORE /:email route)
router.post('/verify-qr', agentController.verifyQR);

// Admin: Get all agents (MUST be before /:email route)
router.get('/all', async (req, res) => {
  try {
    const agents = await Agent.find().sort({ createdAt: -1 });
    res.json({ success: true, agents });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get agent profile by email (MUST be after specific routes like /all)
router.get('/:email', agentController.getProfile);

// Admin: Get all pending verification agents
router.get('/admin/pending', async (req, res) => {
  try {
    const pendingAgents = await Agent.find({ verified: false, documentsUploaded: true });
    res.json({ success: true, agents: pendingAgents });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: Verify agent and generate QR
router.post('/admin/verify/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const { score, notes } = req.body;

    const agent = await Agent.findOne({ email });
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    if (agent.verified) {
      return res.status(400).json({ error: 'Agent already verified' });
    }

    // Generate QR data
    const qrData = JSON.stringify({
      id: agent.id,
      name: agent.name,
      email: agent.email,
      company: agent.company,
      verified: true,
      score: score || 0,
      timestamp: new Date().toISOString()
    });

    // Update agent
    agent.verified = true;
    agent.rejected = false;
    agent.score = score || 0;
    agent.qrData = qrData;
    agent.verificationNotes = notes || '';
    await agent.save();

    res.json({
      success: true,
      message: 'Agent verified successfully',
      agent: {
        id: agent.id,
        name: agent.name,
        verified: agent.verified,
        score: agent.score
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Admin: Reject agent application
router.post('/admin/reject/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const { reason } = req.body;

    const agent = await Agent.findOne({ email });
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    if (agent.verified) {
      return res.status(400).json({ error: 'Cannot reject verified agent' });
    }

    // Update agent
    agent.rejected = true;
    agent.rejectionReason = reason || 'Application rejected by admin';
    agent.rejectedAt = new Date();
    await agent.save();

    res.json({
      success: true,
      message: 'Agent application rejected'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get agent by email - Public route (for Guard QR scanning)
router.get('/verify/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const agent = await Agent.findOne({ email });
    
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    res.json({
      success: true,
      agent: {
        id: agent.id,
        name: agent.name,
        company: agent.company,
        verified: agent.verified,
        score: agent.score
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update agent notification settings
router.put('/:email/settings', async (req, res) => {
  try {
    const { email } = req.params;
    const { notificationSettings } = req.body;

    const agent = await Agent.findOne({ email });
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    agent.notificationSettings = notificationSettings;
    await agent.save();

    res.json({
      success: true,
      message: 'Settings updated successfully',
      notificationSettings: agent.notificationSettings
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
