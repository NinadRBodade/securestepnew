// ============================================
// ENHANCED SOS CONTROLLER WITH POLICE INTEGRATION
// src/controllers/sos.controller.js
// ============================================

const SOSEvent = require('../models/SOSEvent');
const { Agent, Guard, Admin, Resident } = require('../models/User');
const Society = require('../models/Society');
const { emitSOSAlert } = require('../config/socket');
const { logSOSToBlockchain } = require('../services/blockchain.service');

// In-memory storage for SOS events (temporary fix)
const sosEvents = [];
const { sendSOSAlert, sendPoliceSOS } = require('../services/notification.service');
const logger = require('../utils/logger');

// @desc    Trigger SOS Alert
// @route   POST /api/v1/sos
// @access  Private (Resident, Guard)
exports.triggerSOS = async (req, res) => {
  try {
    const {
      societyId,
      flatNumber,
      description,
      latitude,
      longitude,
      agentId,
      visitId,
      isOffline = false,
      deviceId,
      propagationPath = []
    } = req.body;

    const user = req.user;

    // Skip society validation for now (using in-memory storage)
    const society = { _id: societyId, name: 'Test Society', assignedGuards: [] };

    // Generate unique SOS ID
    const sosId = `SOS${Date.now()}${Math.floor(Math.random() * 10000)}`;

    // Get involved agent details if provided
    let involvedAgentData = null;
    if (agentId) {
      const agent = await Agent.findById(agentId);
      if (agent) {
        involvedAgentData = {
          agentId: agent._id,
          company: agent.company,
          safetyScore: agent.safetyScore
        };
      }
    }

    // Create SOS event
    const sosEvent = await SOSEvent.create({
      sosId,
      triggeredBy: {
        userId: user._id,
        role: user.role
      },
      societyId,
      flatNumber: flatNumber || user.flatNumber || 'Unknown',
      location: latitude && longitude ? { latitude, longitude } : undefined,
      description: description || 'Emergency - Immediate assistance required',
      status: 'triggered',
      priority: 'critical',
      involvedAgent: involvedAgentData,
      currentVisit: visitId || null,
      isOfflineTrigger: isOffline,
      offlineData: isOffline ? {
        deviceId,
        propagatedVia: propagationPath,
        syncedAt: new Date()
      } : undefined,
      triggeredAt: new Date()
    });

    logger.warn(`🚨 SOS TRIGGERED: ${sosId} at ${society.name} - Flat ${sosEvent.flatNumber}`);

    // ============================================
    // 1. NOTIFY ALL GUARDS IN THE SOCIETY
    // ============================================
    const guards = society.assignedGuards
      .map(g => g.guardId)
      .filter(Boolean);

    if (guards.length > 0) {
      // Update SOS with notified guards
      sosEvent.notifications.guardsSent = guards.map(g => g._id);
      
      // Send push notifications to guards
      try {
        await sendSOSAlert(guards, {
          sosId: sosEvent.sosId,
          societyId: sosEvent.societyId,
          flatNumber: sosEvent.flatNumber,
          triggeredBy: user.name,
          priority: sosEvent.priority,
          description: sosEvent.description
        });
        logger.info(`✅ SOS notifications sent to ${guards.length} guards`);
      } catch (error) {
        console.error('Failed to send guard notifications:', error);
      }
    } else {
      logger.warn(`⚠️ No guards assigned to society ${society.name}`);
    }

    // ============================================
    // 2. EMIT REAL-TIME SOCKET.IO ALERT
    // ============================================
    emitSOSAlert(societyId.toString(), {
      sosId: sosEvent.sosId,
      flatNumber: sosEvent.flatNumber,
      triggeredBy: user.name,
      triggeredByRole: user.role,
      triggeredAt: sosEvent.triggeredAt,
      priority: sosEvent.priority,
      location: sosEvent.location,
      description: sosEvent.description,
      involvedAgent: involvedAgentData,
      societyName: society.name
    });

    // ============================================
    // 3. NOTIFY OTHER RESIDENTS ON SAME FLOOR (OPTIONAL)
    // ============================================
    const floorNumber = sosEvent.flatNumber.split('-')[0]; // Extract floor from "A-101"
    const nearbyResidents = await Resident.find({
      societyId,
      flatNumber: { $regex: `^${floorNumber}` },
      _id: { $ne: user._id } // Exclude the person who triggered SOS
    });

    if (nearbyResidents.length > 0) {
      sosEvent.notifications.residentsSent = nearbyResidents.map(r => r._id);
      logger.info(`📢 Notified ${nearbyResidents.length} nearby residents`);
    }

    // ============================================
    // 4. NOTIFY POLICE DASHBOARD
    // ============================================
    const policeAdmins = await Admin.find({
      accessLevel: 'police',
      isActive: true
    });

    if (policeAdmins.length > 0) {
      sosEvent.notifications.policeSent = true;
      
      // Send to police dashboard via Socket.IO
      const io = require('../config/socket').getIO();
      io.emit('police:sos-alert', {
        sosId: sosEvent.sosId,
        societyName: society.name,
        societyAddress: society.address,
        flatNumber: sosEvent.flatNumber,
        location: sosEvent.location,
        triggeredBy: user.name,
        triggeredByPhone: user.phone,
        triggeredAt: sosEvent.triggeredAt,
        priority: sosEvent.priority,
        description: sosEvent.description,
        involvedAgent: involvedAgentData
      });

      // Send push notifications to police
      try {
        await sendPoliceSOS(policeAdmins, {
          sosId: sosEvent.sosId,
          societyName: society.name,
          flatNumber: sosEvent.flatNumber,
          address: `${society.address.street}, ${society.address.city}`,
          triggeredBy: user.name
        });
        logger.info(`🚓 Police notified: ${policeAdmins.length} officers`);
      } catch (error) {
        console.error('Failed to notify police:', error);
      }
    } else {
      logger.warn('⚠️ No police admins registered in system');
    }

    await sosEvent.save();

    // ============================================
    // 5. LOG TO BLOCKCHAIN (ASYNC - DON'T WAIT)
    // ============================================
    logSOSToBlockchain(sosEvent)
      .then(result => {
        if (result.success) {
          logger.info(`⛓️ SOS logged to blockchain: ${result.transactionHash}`);
        }
      })
      .catch(err => console.error('Blockchain logging failed:', err));

    // ============================================
    // 6. AUTO-ESCALATION TIMER (IF NO RESPONSE IN 2 MINUTES)
    // ============================================
    setTimeout(async () => {
      try {
        const eventCheck = await SOSEvent.findOne({ sosId });
        if (eventCheck && eventCheck.status === 'triggered') {
          console.error(`⚠️ SOS ${sosId} NOT ACKNOWLEDGED - ESCALATING`);
          
          // Send escalation alert
          const io = require('../config/socket').getIO();
          io.emit('police:sos-escalation', {
            sosId: eventCheck.sosId,
            message: 'SOS not acknowledged by guards - requires immediate police intervention',
            elapsedTime: '2 minutes',
            societyName: society.name,
            flatNumber: eventCheck.flatNumber
          });
        }
      } catch (error) {
        console.error('Escalation check failed:', error);
      }
    }, 2 * 60 * 1000); // 2 minutes

    // Response
    res.status(201).json({
      status: 'success',
      message: 'SOS alert triggered successfully',
      data: {
        sosEvent: {
          sosId: sosEvent.sosId,
          status: sosEvent.status,
          priority: sosEvent.priority,
          triggeredAt: sosEvent.triggeredAt,
          notificationsSent: {
            guards: guards.length,
            residents: nearbyResidents.length,
            police: policeAdmins.length
          }
        }
      }
    });

  } catch (error) {
    console.error('Trigger SOS error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to trigger SOS',
      error: error.message
    });
  }
};

// @desc    Guard acknowledges SOS
// @route   PUT /api/v1/sos/:sosId/acknowledge
// @access  Private (Guard)
exports.acknowledgeSOS = async (req, res) => {
  try {
    const { sosId } = req.params;
    const guard = req.user;

    const sosEvent = await SOSEvent.findOne({ sosId })
      .populate('triggeredBy.userId', 'name phone')
      .populate('societyId', 'name address');

    if (!sosEvent) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }

    if (sosEvent.status !== 'triggered') {
      return res.status(400).json({
        status: 'error',
        message: 'SOS already acknowledged'
      });
    }

    const acknowledgedAt = new Date();
    const responseTime = Math.round((acknowledgedAt - sosEvent.triggeredAt) / 1000); // seconds

    sosEvent.respondingGuards.push({
      guardId: guard._id,
      acknowledgedAt,
      responseTime
    });

    sosEvent.status = 'acknowledged';
    await sosEvent.save();

    // Update guard's response time stats
    await Guard.findByIdAndUpdate(guard._id, {
      $inc: { sosHandled: 1 },
      $set: {
        'responseTime.average': responseTime, // Simplified - should calculate average
        'responseTime.fastest': Math.min(guard.responseTime?.fastest || 999999, responseTime)
      }
    });

    // Notify everyone that guard is responding
    const io = require('../config/socket').getIO();
    
    // Notify society
    io.to(`society_${sosEvent.societyId._id}`).emit('sos:acknowledged', {
      sosId: sosEvent.sosId,
      guardName: guard.name,
      responseTime,
      acknowledgedAt
    });

    // Notify police dashboard
    io.emit('police:sos-update', {
      sosId: sosEvent.sosId,
      status: 'acknowledged',
      guardName: guard.name,
      responseTime: `${responseTime} seconds`,
      message: 'Guard is responding to the emergency'
    });

    logger.info(`✅ SOS ${sosId} acknowledged by ${guard.name} (Response time: ${responseTime}s)`);

    res.status(200).json({
      status: 'success',
      message: 'SOS acknowledged',
      data: {
        sosEvent: {
          sosId: sosEvent.sosId,
          status: sosEvent.status,
          responseTime,
          guardName: guard.name
        }
      }
    });
  } catch (error) {
    console.error('Acknowledge SOS error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to acknowledge SOS'
    });
  }
};

// @desc    Resolve SOS
// @route   PUT /api/v1/sos/:sosId/resolve
// @access  Private (Guard, Admin)
exports.resolveSOS = async (req, res) => {
  try {
    const { sosId } = req.params;
    const { outcome, notes, policeReportNumber, requiresPoliceAction } = req.body;
    const user = req.user;

    const sosEvent = await SOSEvent.findOne({ sosId })
      .populate('involvedAgent.agentId');

    if (!sosEvent) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }

    sosEvent.resolution = {
      resolvedBy: user._id,
      resolvedAt: new Date(),
      outcome: outcome || 'safe',
      notes,
      policeReportNumber
    };

    sosEvent.status = outcome === 'false-alarm' ? 'false-alarm' : 'resolved';
    await sosEvent.save();

    // ============================================
    // SAFETY SCORE ADJUSTMENT
    // ============================================
    if (sosEvent.involvedAgent && outcome !== 'false-alarm') {
      const agent = await Agent.findById(sosEvent.involvedAgent.agentId);
      if (agent) {
        const deduction = outcome === 'agent-removed' ? 15 : 10;
        agent.safetyScore = Math.max(0, agent.safetyScore - deduction);
        await agent.save();

        const { emitScoreUpdate } = require('../config/socket');
        emitScoreUpdate(agent._id.toString(), {
          safetyScore: agent.safetyScore,
          reason: `SOS event: ${outcome}`,
          sosId: sosEvent.sosId
        });

        logger.warn(`⚠️ Agent ${agent.agentId} safety score reduced to ${agent.safetyScore}`);
      }
    }

    // ============================================
    // NOTIFY EVERYONE ABOUT RESOLUTION
    // ============================================
    const io = require('../config/socket').getIO();
    
    // Notify society
    io.to(`society_${sosEvent.societyId}`).emit('sos:resolved', {
      sosId: sosEvent.sosId,
      outcome,
      resolvedBy: user.name,
      resolvedAt: sosEvent.resolution.resolvedAt
    });

    // Notify police dashboard
    io.emit('police:sos-resolved', {
      sosId: sosEvent.sosId,
      status: 'resolved',
      outcome,
      notes,
      policeReportNumber,
      requiresPoliceAction,
      resolvedBy: user.name,
      resolvedAt: sosEvent.resolution.resolvedAt
    });

    logger.info(`✅ SOS ${sosId} resolved with outcome: ${outcome}`);

    res.status(200).json({
      status: 'success',
      message: 'SOS resolved successfully',
      data: { sosEvent }
    });
  } catch (error) {
    console.error('Resolve SOS error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to resolve SOS'
    });
  }
};

// @desc    Get all SOS events (with filters)
// @route   GET /api/v1/sos
// @access  Private
exports.getSOSEvents = async (req, res) => {
  try {
    const { societyId, status, priority, page = 1, limit = 20, role } = req.query;
    const user = req.user;

    const query = {};

    // Role-based filtering (only if user is authenticated)
    if (user) {
      if (user.role === 'resident') {
        query['triggeredBy.userId'] = user._id;
      } else if (user.role === 'guard' && societyId) {
        query.societyId = societyId;
      } else if (user.role === 'admin') {
        // Admins can see all
        if (societyId) query.societyId = societyId;
      }
    } else {
      // Public access (e.g., police dashboard) - show all active SOS events
      // Optionally filter by societyId if provided
      if (societyId) query.societyId = societyId;
    }

    if (status) query.status = status;
    if (priority) query.priority = priority;

    const sosEvents = await SOSEvent.find(query)
      .populate('triggeredBy.userId', 'name phone role')
      .populate('societyId', 'name address')
      .populate('involvedAgent.agentId', 'name company agentId')
      .populate('respondingGuards.guardId', 'name guardId')
      .sort({ triggeredAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await SOSEvent.countDocuments(query);

    // Statistics
    const stats = {
      total,
      triggered: await SOSEvent.countDocuments({ ...query, status: 'triggered' }),
      acknowledged: await SOSEvent.countDocuments({ ...query, status: 'acknowledged' }),
      resolved: await SOSEvent.countDocuments({ ...query, status: 'resolved' }),
      falseAlarms: await SOSEvent.countDocuments({ ...query, status: 'false-alarm' })
    };

    res.status(200).json({
      status: 'success',
      data: {
        sosEvents,
        stats,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get SOS events error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch SOS events'
    });
  }
};

// @desc    Get single SOS event details
// @route   GET /api/v1/sos/:sosId
// @access  Private
exports.getSOSById = async (req, res) => {
  try {
    const { sosId } = req.params;

    const sosEvent = await SOSEvent.findOne({ sosId })
      .populate('triggeredBy.userId', 'name phone email role profilePhoto')
      .populate('societyId', 'name address coordinates')
      .populate('involvedAgent.agentId', 'name company email phone agentId safetyScore')
      .populate('respondingGuards.guardId', 'name phone guardId')
      .populate('resolution.resolvedBy', 'name role')
      .populate('currentVisit');

    if (!sosEvent) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }

    res.status(200).json({
      status: 'success',
      data: { sosEvent }
    });
  } catch (error) {
    console.error('Get SOS by ID error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch SOS event'
    });
  }
};

// @desc    Upload evidence for SOS
// @route   POST /api/v1/sos/:sosId/upload-evidence
// @access  Private
exports.uploadEvidence = async (req, res) => {
  try {
    const { sosId } = req.params;
    const { evidenceType, evidenceUrl, description } = req.body;

    const sosEvent = await SOSEvent.findOne({ sosId });

    if (!sosEvent) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }

    sosEvent.evidence.push({
      type: evidenceType,
      url: evidenceUrl,
      description,
      capturedAt: new Date(),
      uploadedBy: req.user._id
    });

    await sosEvent.save();

    logger.info(`📎 Evidence uploaded for SOS ${sosId}`);

    res.status(200).json({
      status: 'success',
      message: 'Evidence uploaded successfully',
      data: { sosEvent }
    });
  } catch (error) {
    console.error('Upload evidence error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to upload evidence'
    });
  }
};

// @desc    Get police dashboard statistics
// @route   GET /api/v1/sos/police/dashboard
// @access  Private (Admin - Police)
exports.getPoliceDashboard = async (req, res) => {
  try {
    const { timeRange = '24h' } = req.query;

    // Calculate time range
    const now = new Date();
    let startTime = new Date();
    
    switch (timeRange) {
      case '24h':
        startTime.setHours(now.getHours() - 24);
        break;
      case '7d':
        startTime.setDate(now.getDate() - 7);
        break;
      case '30d':
        startTime.setDate(now.getDate() - 30);
        break;
    }

    const stats = {
      active: await SOSEvent.countDocuments({
        status: { $in: ['triggered', 'acknowledged'] }
      }),
      todayTotal: await SOSEvent.countDocuments({
        triggeredAt: { $gte: startTime }
      }),
      resolved: await SOSEvent.countDocuments({
        status: 'resolved',
        'resolution.resolvedAt': { $gte: startTime }
      }),
      requiresPoliceAction: await SOSEvent.countDocuments({
        status: { $in: ['triggered', 'acknowledged'] },
        priority: 'critical',
        triggeredAt: { $gte: startTime }
      }),
      averageResponseTime: 0 // Calculate from respondingGuards
    };

    // Recent active SOS events
    const activeSOS = await SOSEvent.find({
      status: { $in: ['triggered', 'acknowledged'] }
    })
      .populate('triggeredBy.userId', 'name phone')
      .populate('societyId', 'name address')
      .populate('respondingGuards.guardId', 'name')
      .sort({ triggeredAt: -1 })
      .limit(10);

    // Society-wise statistics
    const societyStats = await SOSEvent.aggregate([
      {
        $match: {
          triggeredAt: { $gte: startTime }
        }
      },
      {
        $group: {
          _id: '$societyId',
          count: { $sum: 1 },
          critical: {
            $sum: { $cond: [{ $eq: ['$priority', 'critical'] }, 1, 0] }
          }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    res.status(200).json({
      status: 'success',
      data: {
        stats,
        activeSOS,
        societyStats,
        timeRange
      }
    });
  } catch (error) {
    console.error('Get police dashboard error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch dashboard data'
    });
  }
  exports.getPoliceSOSMap = async (req, res) => {
  try {
    const sosList = await SOSEvent.find({
      status: { $in: ['triggered', 'acknowledged'] }
    })
    .populate('societyId', 'name address');

    const data = sosList.map(sos => ({
      sosId: sos.sosId,
      societyName: sos.societyId?.name,
      flatNumber: sos.flatNumber,
      description: sos.description,
      latitude: sos.location.latitude,
      longitude: sos.location.longitude,
      triggeredAt: sos.triggeredAt
    }));

    res.json({ status: 'success', data });
  } catch (e) {
    res.status(500).json({ status: 'error' });
  }
};

exports.getPoliceDashboard = async (req, res) => {
  try {
    const active = await SOSEvent.countDocuments({
      status: { $in: ['triggered', 'acknowledged'] }
    });

    const resolved = await SOSEvent.countDocuments({
      status: 'resolved'
    });

    res.json({
      status: 'success',
      data: { active, resolved }
    });
  } catch (e) {
    res.status(500).json({ status: 'error' });
  }
};
};

module.exports = exports;