// Hybrid SOS Controller - In-memory + MongoDB storage
const socketService = require('../services/socket.service');
const blockchainService = require('../services/blockchainService');
const SOSEvent = require('../models/SOSEvent');

// In-memory storage (for real-time operations)
const sosEvents = [];

// Sanitize SOS event - remove sensitive blockchain hash from responses
const sanitizeSOSEvent = (event, userRole = null, isDetailedView = false) => {
  if (!event) return event;
  
  const sanitized = { ...event };
  
  // Remove blockchainHash unless admin AND detailed view
  if (userRole !== 'admin' || !isDetailedView) {
    delete sanitized.blockchainHash;
  }
  
  return sanitized;
};

// Sanitize array of SOS events
const sanitizeSOSEvents = (events, userRole = null) => {
  return events.map(e => sanitizeSOSEvent(e, userRole, false));
};

// Trigger SOS
exports.triggerSOS = async (req, res) => {
  try {
    const {
      societyId,
      flatNumber,
      description,
      latitude,
      longitude
    } = req.body;

    const user = req.user;
    const sosId = `SOS${Date.now()}${Math.floor(Math.random() * 10000)}`;

    // Create SOS event
    const sosEvent = {
      _id: sosId,
      sosId,
      triggeredBy: {
        userId: user.id,
        name: user.name || user.fullName || 'Unknown User',
        email: user.email,
        phone: user.phone || user.mobile,
        role: user.role
      },
      societyId: societyId || 'default-society',
      flatNumber: flatNumber || 'Unknown',
      location: latitude && longitude ? { 
        latitude, 
        longitude,
        address: req.body.locationAddress || null
      } : null,
      locationAddress: req.body.locationAddress || description || '',
      description: description || 'Emergency - Immediate assistance required',
      status: 'triggered',
      priority: 'critical',
      triggeredAt: new Date(),
      notifications: {
        guardsSent: [],
        policeNotified: true
      }
    };

    // Prepare data for hash generation (immutable fields only)
    const sosDataForHash = {
      sosId: sosId,
      userId: user.id,
      flatNumber: sosEvent.flatNumber,
      latitude: latitude ? String(latitude) : null,
      longitude: longitude ? String(longitude) : null,
      description: sosEvent.description,
      triggeredAt: sosEvent.triggeredAt // Will be normalized to ISO in getHashPayload
    };

    // Generate blockchain-style hash for data integrity
    const blockchainHash = blockchainService.generateHash(sosDataForHash);
    console.log('🔐 Blockchain hash generated for SOS');

    // Save to MongoDB FIRST (PRIMARY - persistent storage)
    const savedSOS = await SOSEvent.create({
      sosId: sosId,
      userId: user.id,
      userName: user.name || user.fullName || 'Unknown User',
      userRole: user.role,
      flatNumber: sosEvent.flatNumber,
      triggeredAt: sosEvent.triggeredAt, // Store exact timestamp used in hash
      latitude: latitude ? String(latitude) : null,
      longitude: longitude ? String(longitude) : null,
      locationAddress: sosEvent.locationAddress,
      status: 'active',
      description: sosEvent.description,
      blockchainHash: blockchainHash,
      isSynced: true
    });
    console.log('💾 SOS saved to MongoDB:', sosId);

    // THEN add to in-memory cache (SECONDARY - for real-time Socket.IO)
    sosEvent.blockchainHash = blockchainHash;
    sosEvents.push(sosEvent);

    console.warn(`🚨 SOS TRIGGERED: ${sosId} - Flat ${sosEvent.flatNumber}`);
    console.log('📍 Location:', latitude, longitude);

    // Emit to BOTH police AND guards via Socket.IO
    try {
      // Use socket service to notify everyone
      socketService.emitSOSAlert(sosEvent);
      console.log('✅ Police and guards notified via Socket.IO');
    } catch (error) {
      console.error('❌ Failed to notify police/guards:', error);
      console.error(error);
    }

    // Return success (sanitize response - hide hash from user)
    res.status(201).json({
      status: 'success',
      message: 'SOS triggered successfully',
      data: { sosEvent: sanitizeSOSEvent(sosEvent, user.role) }
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

// Get all SOS events
exports.getSOSEvents = async (req, res) => {
  try {
    const userRole = req.user ? req.user.role : null;
    const { mine } = req.query; // Support ?mine=true for user's own SOS history
    
    // Build query filter
    let filter = {};
    if (mine === 'true' && req.user) {
      filter.userId = req.user.id;
    }
    
    // Fetch from MongoDB (PRIMARY storage)
    const dbEvents = await SOSEvent.find(filter).sort({ createdAt: -1 }).lean();
    
    console.log(`📊 Retrieved ${dbEvents.length} SOS events from MongoDB`);
    
    // Return MongoDB documents directly with minimal transformation
    const sosEvents = dbEvents.map(doc => ({
      _id: doc._id.toString(),
      sosId: doc.sosId || doc._id.toString(),
      userId: doc.userId,
      userName: doc.userName,
      userRole: doc.userRole,
      flatNumber: doc.flatNumber,
      triggeredAt: doc.triggeredAt || doc.createdAt,
      latitude: doc.latitude,
      longitude: doc.longitude,
      locationAddress: doc.locationAddress,
      description: doc.description,
      status: doc.status,
      agentId: doc.agentId,
      agentName: doc.agentName,
      guardId: doc.guardId,
      acknowledgedAt: doc.acknowledgedAt,
      resolvedAt: doc.resolvedAt,
      resolutionNotes: doc.resolutionNotes,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt
    }));
    
    res.json({
      status: 'success',
      data: { 
        events: sosEvents,
        count: sosEvents.length 
      }
    });
  } catch (error) {
    console.error('Get SOS events error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get SOS events',
      error: error.message
    });
  }
};

// Get single SOS by ID
exports.getSOSById = async (req, res) => {
  try {
    const { sosId } = req.params;
    
    // Find by custom sosId field (not MongoDB _id)
    const doc = await SOSEvent.findOne({ sosId }).lean();
    
    if (!doc) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }
    
    // Transform to frontend format
    const sosEvent = {
      _id: doc.sosId || doc._id,
      sosId: doc.sosId || doc._id.toString(),
      triggeredBy: {
        userId: doc.userId,
        name: doc.userName,
        role: doc.userRole
      },
      flatNumber: doc.flatNumber,
      societyId: 'default-society',
      location: doc.latitude && doc.longitude ? {
        latitude: parseFloat(doc.latitude),
        longitude: parseFloat(doc.longitude),
        address: doc.locationAddress
      } : null,
      locationAddress: doc.locationAddress,
      description: doc.description,
      status: doc.status === 'active' ? 'triggered' : doc.status,
      priority: 'critical',
      triggeredAt: doc.createdAt,
      blockchainHash: doc.blockchainHash
    };

    const userRole = req.user ? req.user.role : null;
    res.json({
      status: 'success',
      data: { sosEvent: sanitizeSOSEvent(sosEvent, userRole, true) }
    });
  } catch (error) {
    console.error('Get SOS by ID error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get SOS event'
    });
  }
};

// Acknowledge SOS
exports.acknowledgeSOS = async (req, res) => {
  try {
    const { sosId } = req.params;
    
    // Update in MongoDB using custom sosId field
    const doc = await SOSEvent.findOneAndUpdate(
      { sosId },
      { status: 'acknowledged', acknowledgedAt: new Date() },
      { new: true }
    ).lean();

    if (!doc) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }
    
    // Also update in-memory cache for Socket.IO
    const memoryEvent = sosEvents.find(s => s.sosId === sosId || s._id === sosId);
    if (memoryEvent) {
      memoryEvent.status = 'acknowledged';
      memoryEvent.acknowledgedAt = new Date();
    }
    
    // Transform to frontend format
    const sosEvent = {
      _id: doc.sosId || doc._id,
      sosId: doc.sosId || doc._id.toString(),
      triggeredBy: {
        userId: doc.userId,
        name: doc.userName,
        role: doc.userRole
      },
      flatNumber: doc.flatNumber,
      status: doc.status,
      acknowledgedAt: doc.acknowledgedAt,
      blockchainHash: doc.blockchainHash
    };

    const userRole = req.user ? req.user.role : null;
    res.json({
      status: 'success',
      data: { sosEvent: sanitizeSOSEvent(sosEvent, userRole) }
    });
  } catch (error) {
    console.error('Acknowledge SOS error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to acknowledge SOS'
    });
  }
};

// Mark guard arrived
exports.markArrived = async (req, res) => {
  try {
    const { sosId } = req.params;
    
    // Update in MongoDB using custom sosId field
    const doc = await SOSEvent.findOneAndUpdate(
      { sosId },
      { status: 'acknowledged', guardArrivedAt: new Date() },
      { new: true }
    ).lean();

    if (!doc) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }
    
    // Also update in-memory cache for Socket.IO
    const memoryEvent = sosEvents.find(s => s.sosId === sosId || s._id === sosId);
    if (memoryEvent) {
      memoryEvent.status = 'arrived';
      memoryEvent.guardArrivedAt = new Date();
    }
    
    // Transform to frontend format
    const sosEvent = {
      _id: doc.sosId || doc._id,
      sosId: doc.sosId || doc._id.toString(),
      status: 'arrived',
      guardArrivedAt: doc.guardArrivedAt || new Date(),
      blockchainHash: doc.blockchainHash
    };

    const userRole = req.user ? req.user.role : null;
    res.json({
      status: 'success',
      data: { sosEvent: sanitizeSOSEvent(sosEvent, userRole) }
    });
  } catch (error) {
    console.error('Mark arrived error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to mark arrived'
    });
  }
};

// Resolve SOS
exports.resolveSOS = async (req, res) => {
  try {
    const { sosId } = req.params;
    const { outcome, notes } = req.body;
    
    // Update in MongoDB using custom sosId field
    const doc = await SOSEvent.findOneAndUpdate(
      { sosId },
      { 
        status: 'resolved', 
        resolvedAt: new Date(),
        resolutionNotes: notes
      },
      { new: true }
    ).lean();

    if (!doc) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }
    
    // Also update in-memory cache
    const memoryEvent = sosEvents.find(s => s.sosId === sosId || s._id === sosId);
    if (memoryEvent) {
      memoryEvent.status = 'resolved';
      memoryEvent.resolvedAt = new Date();
      memoryEvent.resolution = { outcome, notes };
    }
    
    // Transform to frontend format
    const sosEvent = {
      _id: doc.sosId || doc._id,
      sosId: doc.sosId || doc._id.toString(),
      status: doc.status,
      resolvedAt: doc.resolvedAt,
      resolution: { outcome, notes },
      blockchainHash: doc.blockchainHash
    };

    const userRole = req.user ? req.user.role : null;
    res.json({
      status: 'success',
      data: { sosEvent: sanitizeSOSEvent(sosEvent, userRole) }
    });
  } catch (error) {
    console.error('Resolve SOS error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to resolve SOS'
    });
  }
};

// Upload evidence
exports.uploadEvidence = async (req, res) => {
  try {
    const { sosId } = req.params;
    const sosEvent = sosEvents.find(s => s.sosId === sosId || s._id === sosId);

    if (!sosEvent) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }

    if (!sosEvent.evidence) sosEvent.evidence = [];
    sosEvent.evidence.push(req.body);

    const userRole = req.user ? req.user.role : null;
    res.json({
      status: 'success',
      data: { sosEvent: sanitizeSOSEvent(sosEvent, userRole) }
    });
  } catch (error) {
    console.error('Upload evidence error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to upload evidence'
    });
  }
};

// Police dashboard
exports.getPoliceDashboard = async (req, res) => {
  try {
    // Fetch from MongoDB (PRIMARY storage)
    const dbEvents = await SOSEvent.find().sort({ createdAt: -1 }).lean();
    
    // Transform MongoDB format to frontend format
    const sosEvents = dbEvents.map(doc => ({
      _id: doc.sosId || doc._id,
      sosId: doc.sosId || doc._id.toString(),
      triggeredBy: {
        userId: doc.userId,
        name: doc.userName,
        role: doc.userRole
      },
      flatNumber: doc.flatNumber,
      societyId: 'default-society',
      location: doc.latitude && doc.longitude ? {
        latitude: parseFloat(doc.latitude),
        longitude: parseFloat(doc.longitude),
        address: doc.locationAddress
      } : null,
      locationAddress: doc.locationAddress,
      description: doc.description,
      status: doc.status === 'active' ? 'triggered' : doc.status,
      priority: 'critical',
      triggeredAt: doc.createdAt,
      blockchainHash: doc.blockchainHash
    }));
    
    // Police dashboard list view - NEVER include blockchainHash
    res.json({
      status: 'success',
      data: { sosEvents: sanitizeSOSEvents(sosEvents, 'police') }
    });
  } catch (error) {
    console.error('Get police dashboard error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get dashboard'
    });
  }
};

// Police SOS map
exports.getPoliceSOSMap = async (req, res) => {
  try {
    // Fetch from MongoDB - only events with location data
    const dbEvents = await SOSEvent.find({ 
      latitude: { $exists: true, $ne: null },
      longitude: { $exists: true, $ne: null }
    }).sort({ createdAt: -1 }).lean();
    
    // Transform MongoDB format to frontend format
    const eventsWithLocation = dbEvents.map(doc => ({
      _id: doc.sosId || doc._id,
      sosId: doc.sosId || doc._id.toString(),
      triggeredBy: {
        userId: doc.userId,
        name: doc.userName,
        role: doc.userRole
      },
      flatNumber: doc.flatNumber,
      societyId: 'default-society',
      location: {
        latitude: parseFloat(doc.latitude),
        longitude: parseFloat(doc.longitude),
        address: doc.locationAddress
      },
      locationAddress: doc.locationAddress,
      description: doc.description,
      status: doc.status === 'active' ? 'triggered' : doc.status,
      priority: 'critical',
      triggeredAt: doc.createdAt,
      blockchainHash: doc.blockchainHash
    }));
    
    res.json({
      status: 'success',
      data: { sosEvents: sanitizeSOSEvents(eventsWithLocation, 'police') }
    });
  } catch (error) {
    console.error('Get police SOS map error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get map data'
    });
  }
};

// Verify SOS blockchain hash (tamper detection)
exports.verifySOS = async (req, res) => {
  try {
    const { sosId } = req.params;
    
    // Find SOS record from MongoDB (PRIMARY storage)
    // sosId parameter could be either custom sosId or MongoDB _id
    let doc = await SOSEvent.findOne({ sosId }).lean();
    
    // If not found by sosId, try by MongoDB _id
    if (!doc) {
      doc = await SOSEvent.findById(sosId).lean();
    }
    
    if (!doc) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }

    // Check if hash exists
    if (!doc.blockchainHash) {
      return res.status(400).json({
        status: 'error',
        message: 'SOS event has no blockchain hash (created before verification feature)',
        verified: false
      });
    }

    // Prepare data for hash verification using SAME immutable fields as creation
    // Use triggeredAt from MongoDB (the exact timestamp used during creation)
    const sosDataForVerification = {
      sosId: doc.sosId || doc._id.toString(),
      userId: doc.userId,
      flatNumber: doc.flatNumber,
      latitude: doc.latitude,
      longitude: doc.longitude,
      description: doc.description,
      triggeredAt: doc.triggeredAt // Use stored triggeredAt, will be normalized in getHashPayload
    };

    // Verify hash integrity using blockchainService
    const verification = blockchainService.verifyHash(sosDataForVerification, doc.blockchainHash);

    console.log(`🔍 Verification result for ${doc.sosId || sosId}:`, verification.message);

    res.json({
      status: 'success',
      data: {
        sosId: doc.sosId || doc._id.toString(),
        verified: verification.verified,
        message: verification.message,
        hash: doc.blockchainHash,
        timestamp: doc.createdAt
      }
    });

  } catch (error) {
    console.error('Verify SOS error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Verification failed',
      error: error.message
    });
  }
};

// Get guard contact for SOS (resident viewing guard info)
exports.getGuardContact = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Find SOS event (using sosId or MongoDB _id)
    let sosEvent = await SOSEvent.findOne({ sosId: id });
    if (!sosEvent) {
      sosEvent = await SOSEvent.findById(id);
    }
    
    if (!sosEvent) {
      return res.status(404).json({
        status: 'error',
        message: 'SOS event not found'
      });
    }
    
    // Check if user is the SOS creator (residents can only see guard info for their own SOS)
    if (req.user.role === 'resident' && sosEvent.userId !== req.user.id) {
      return res.status(403).json({
        status: 'error',
        message: 'Access denied'
      });
    }
    
    // Get guard information from User model
    const User = require('../models/User');
    const guards = await User.find({ 
      role: 'guard',
      isActive: true 
    }).select('name phone email').lean();
    
    if (!guards || guards.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'No active guards found'
      });
    }
    
    // Return guard contact information
    res.json({
      status: 'success',
      data: {
        sosId: sosEvent.sosId || sosEvent._id.toString(),
        status: sosEvent.status,
        guards: guards.map(guard => ({
          name: guard.name,
          phone: guard.phone,
          email: guard.email
        }))
      }
    });
    
  } catch (error) {
    console.error('Get guard contact error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get guard contact',
      error: error.message
    });
  }
};
