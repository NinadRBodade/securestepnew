const express = require('express');
const router = express.Router();
const Agent = require('../models/Agent');

// POST /api/verify-agent
// Verify agent QR code data
router.post('/verify-agent', async (req, res) => {
  try {
    console.log('========================================');
    console.log('VERIFY AGENT API HIT');
    console.log('Request body:', JSON.stringify(req.body, null, 2));
    console.log('========================================');

    const qrData = req.body;

    // Validate required fields
    if (!qrData || !qrData.id || !qrData.email) {
      console.log('❌ Missing required fields');
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid QR code: missing required fields (id, email)' 
      });
    }

    // Find agent by id or email
    const agent = await Agent.findOne({ 
      $or: [
        { id: qrData.id },
        { email: qrData.email }
      ]
    });

    if (!agent) {
      console.log('❌ Agent not found in database');
      return res.status(404).json({ 
        success: false, 
        message: 'Agent not found in database' 
      });
    }

    console.log('✅ Agent verified:', agent.name);

    // Return agent details as JSON
    return res.status(200).json({
      success: true,
      message: 'Agent verified successfully',
      agent: {
        id: agent.id,
        name: agent.name,
        email: agent.email,
        phone: agent.phone,
        company: agent.company,
        verified: agent.verified,
        score: agent.score || 0,
        documentsUploaded: agent.documentsUploaded || false,
        serviceType: agent.serviceType || 'General'
      }
    });

  } catch (error) {
    console.error('❌ Error in verify-agent:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Server error during verification',
      error: error.message 
    });
  }
});

module.exports = router;
