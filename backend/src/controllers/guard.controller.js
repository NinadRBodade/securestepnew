const Agent = require('../models/Agent');
const EntryLog = require('../models/EntryLog');

// Sync offline entry from guard
exports.syncOfflineEntry = async (req, res) => {
  try {
    const { 
      agentId, 
      name, 
      email, 
      company, 
      action, 
      timestamp, 
      verified, 
      score,
      isOfflineVerified 
    } = req.body;

    if (!agentId || !name || !email || !action) {
      return res.status(400).json({ 
        status: 'error', 
        message: 'Missing required fields' 
      });
    }

    // Find or create agent
    let agent = await Agent.findOne({ id: agentId });
    
    if (!agent) {
      agent = await Agent.create({
        id: agentId,
        name,
        email,
        company,
        verified,
        score,
        isInside: action === 'CHECK_IN'
      });
    } else {
      // Update agent status based on action
      agent.isInside = action === 'CHECK_IN';
      if (action === 'CHECK_IN') {
        agent.lastCheckIn = timestamp || new Date();
      } else {
        agent.lastCheckOut = timestamp || new Date();
      }
      await agent.save();
    }

    // Log entry/exit with offline flag
    await EntryLog.create({
      agentId: agent.id,
      name: agent.name,
      company: agent.company || '',
      action,
      timestamp: timestamp || new Date(),
      isOfflineVerified: isOfflineVerified || false,
    });

    // Emit socket event
    if (global.io) {
      global.io.emit('agent:status-update', { 
        agentId: agent.id, 
        action, 
        agent,
        synced: true 
      });
    }

    console.log(`🔄 Synced offline ${action}: ${agent.name} at ${timestamp}`);

    res.status(201).json({ 
      status: 'success', 
      message: 'Offline entry synced successfully',
      data: agent 
    });
  } catch (error) {
    console.error('Sync offline entry error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Scan agent QR - Toggle entry/exit
exports.scanAgent = async (req, res) => {
  try {
    const { id, name, email, company, verified, score } = req.body;

    if (!id || !name || !email) {
      return res.status(400).json({ status: 'error', message: 'Missing required fields' });
    }

    // Find or create agent
    let agent = await Agent.findOne({ id });
    
    if (!agent) {
      agent = await Agent.create({
        id,
        name,
        email,
        company,
        verified,
        score,
        isInside: false
      });
    }

    // Toggle entry/exit
    const action = agent.isInside ? 'CHECK_OUT' : 'CHECK_IN';
    
    if (action === 'CHECK_IN') {
      agent.isInside = true;
      agent.lastCheckIn = new Date();
    } else {
      agent.isInside = false;
      agent.lastCheckOut = new Date();
    }

    await agent.save();

    // Log entry/exit
    await EntryLog.create({
      agentId: agent.id,
      name: agent.name,
      company: agent.company,
      action,
      timestamp: new Date()
    });

    // Emit socket event
    if (global.io) {
      global.io.emit('agent:status-update', { agentId: agent.id, action, agent });
    }

    console.log(`🚪 Agent ${action}: ${agent.name} (${agent.company})`);

    res.json({ 
      status: 'success', 
      action,
      message: `${action === 'CHECK_IN' ? 'Check-in' : 'Check-out'} successful`,
      data: agent 
    });
  } catch (error) {
    console.error('Scan agent error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Get active agents (currently inside)
exports.getActiveAgents = async (req, res) => {
  try {
    const agents = await Agent.find({ isInside: true }).sort({ lastCheckIn: -1 });
    res.json({ status: 'success', data: agents });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Get entry/exit logs
exports.getEntryLogs = async (req, res) => {
  try {
    const logs = await EntryLog.find().sort({ timestamp: -1 }).limit(100);
    res.json({ status: 'success', data: logs });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Verify agent
exports.verifyAgent = async (req, res) => {
  try {
    const { agentId } = req.params;
    
    const agent = await Agent.findByIdAndUpdate(
      agentId,
      { 
        status: 'verified',
        verifiedBy: req.user.id,
        verifiedAt: new Date()
      },
      { new: true }
    );

    if (!agent) {
      return res.status(404).json({ status: 'error', message: 'Agent not found' });
    }

    // Create visit entry
    await Visit.create({
      personType: 'agent',
      agentId: agent._id,
      name: agent.name,
      phone: agent.phone,
      company: agent.company,
      purpose: agent.purpose,
      flatNumber: agent.flatNumber,
      societyId: agent.societyId || req.user.societyId,
      verifiedBy: req.user.id,
      status: 'active'
    });

    // Emit socket event
    if (global.io) {
      global.io.emit('agent:verified', { agentId, agent });
    }

    res.json({ status: 'success', message: 'Agent verified', data: agent });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Reject agent
exports.rejectAgent = async (req, res) => {
  try {
    const { agentId } = req.params;
    
    const agent = await Agent.findByIdAndUpdate(
      agentId,
      { status: 'rejected' },
      { new: true }
    );

    if (!agent) {
      return res.status(404).json({ status: 'error', message: 'Agent not found' });
    }

    res.json({ status: 'success', message: 'Agent rejected', data: agent });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Get active visitors
exports.getActiveVisitors = async (req, res) => {
  try {
    const { societyId } = req.query;
    
    const visitors = await Visit.find({
      societyId: societyId || req.user.societyId,
      status: 'active'
    }).sort({ entryTime: -1 });

    res.json({ status: 'success', data: visitors });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Get entry/exit logs
exports.getLogs = async (req, res) => {
  try {
    const { societyId } = req.query;
    
    const logs = await Visit.find({
      societyId: societyId || req.user.societyId
    }).sort({ createdAt: -1 }).limit(100);

    res.json({ status: 'success', data: logs });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Mark exit
exports.markExit = async (req, res) => {
  try {
    const { visitId } = req.params;
    
    const visit = await Visit.findByIdAndUpdate(
      visitId,
      { 
        status: 'completed',
        exitTime: new Date()
      },
      { new: true }
    );

    if (!visit) {
      return res.status(404).json({ status: 'error', message: 'Visit not found' });
    }

    res.json({ status: 'success', message: 'Exit marked', data: visit });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Report incident
exports.reportIncident = async (req, res) => {
  try {
    const { title, description, flatNumber, severity } = req.body;
    
    if (!title || !description) {
      return res.status(400).json({ status: 'error', message: 'Title and description required' });
    }

    const incident = await Incident.create({
      reportedBy: req.user.id,
      title,
      description,
      flatNumber,
      societyId: req.user.societyId,
      severity: severity || 'medium',
      status: 'open'
    });

    console.log(`📝 Incident reported: ${incident._id} by ${req.user.name}`);

    res.status(201).json({ status: 'success', message: 'Incident reported', data: incident });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Get incidents
exports.getIncidents = async (req, res) => {
  try {
    const { societyId } = req.query;
    
    const incidents = await Incident.find({
      societyId: societyId || req.user.societyId
    }).sort({ createdAt: -1 });

    res.json({ status: 'success', data: incidents });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Keep old functions for compatibility


exports.getActiveEntries = async (req, res) => {
  const visits = await Visit.find({
    societyId: req.params.societyId,
    status: 'active'
  });

  res.json({ status: 'success', data: visits });
};

exports.getVisitLogs = async (req, res) => {
  const visits = await Visit.find({
    societyId: req.params.societyId
  }).sort({ createdAt: -1 });

  res.json({ status: 'success', data: visits });
};

exports.markExit = async (req, res) => {
  const visit = await Visit.findByIdAndUpdate(
    req.params.visitId,
    { status: 'completed', exitTime: new Date() },
    { new: true }
  );

  res.json({ status: 'success', data: visit });
};
