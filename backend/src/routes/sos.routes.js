// ============================================
// COMPLETE SOS ROUTES
// src/routes/sos.routes.js
// ============================================

const express = require('express');
const router = express.Router();
const sosController = require('../controllers/sos.controller');
const { protect, authorize, sosLimiter } = require('../middleware/auth.middleware');
const validationMiddleware = require('../middleware/validation.middleware');
const validate = validationMiddleware.validate;
const Joi = require('joi');

// Validation schemas
const triggerSOSSchema = Joi.object({
  societyId: Joi.string().required(),
  flatNumber: Joi.string().required(),
  description: Joi.string().optional(),
  latitude: Joi.number().optional(),
  longitude: Joi.number().optional(),
  agentId: Joi.string().optional(),
  visitId: Joi.string().optional(),
  isOffline: Joi.boolean().default(false),
  deviceId: Joi.string().optional(),
  propagationPath: Joi.array().items(Joi.string()).optional()
});

const resolveSOSSchema = Joi.object({
  outcome: Joi.string()
    .valid('safe', 'police-called', 'agent-removed', 'false-alarm')
    .required(),
  notes: Joi.string().optional(),
  policeReportNumber: Joi.string().optional(),
  requiresPoliceAction: Joi.boolean().default(false)
});

const uploadEvidenceSchema = Joi.object({
  evidenceType: Joi.string().valid('photo', 'video', 'audio').required(),
  evidenceUrl: Joi.string().uri().required(),
  description: Joi.string().optional()
});

// ============================================
// PUBLIC ROUTES FOR POLICE DASHBOARD
// (No authentication required)
// ============================================

// Get all SOS events for police dashboard
router.get('/police/dashboard', sosController.getSOSEvents);

// Get single SOS event for police dashboard
router.get('/police/:sosId', sosController.getSOSById);

// Verify SOS blockchain hash (PUBLIC - for transparency)
router.get('/:sosId/verify', sosController.verifySOS);

// ============================================
// PROTECTED ROUTES (Authentication required)
// ============================================
router.use(protect);

// Get guard contact for SOS (residents viewing guard info for their SOS)
router.get('/:id/guard', sosController.getGuardContact);

// Trigger SOS (Rate limited to prevent spam)
router.post(
  '/',
  sosLimiter,
  authorize('resident', 'guard'),
  sosController.triggerSOS
);

// Get all SOS events (with filters)
router.get('/', sosController.getSOSEvents);

// Get single SOS event details
router.get('/:sosId', sosController.getSOSById);

// Guard acknowledges SOS
router.put(
  '/:sosId/acknowledge',
  authorize('guard', 'admin'),
  sosController.acknowledgeSOS
);

// Mark guard as arrived at location
router.put(
  '/:sosId/arrived',
  authorize('guard'),
  async (req, res) => {
    try {
      const { sosId } = req.params;
      const guard = req.user;

      const SOSEvent = require('../models/SOSEvent');
      const sosEvent = await SOSEvent.findOne({ sosId });

      if (!sosEvent) {
        return res.status(404).json({
          status: 'error',
          message: 'SOS event not found'
        });
      }

      const guardResponse = sosEvent.respondingGuards.find(
        g => g.guardId.toString() === guard._id.toString()
      );

      if (guardResponse) {
        guardResponse.arrivedAt = new Date();
        await sosEvent.save();

        // Notify via socket
        const io = require('../config/socket').getIO();
        io.to(`society_${sosEvent.societyId}`).emit('guard:arrived', {
          sosId: sosEvent.sosId,
          guardName: guard.name,
          arrivedAt: guardResponse.arrivedAt
        });

        return res.status(200).json({
          status: 'success',
          message: 'Arrival confirmed',
          data: { sosEvent }
        });
      }

      res.status(400).json({
        status: 'error',
        message: 'Guard has not acknowledged this SOS'
      });
    } catch (error) {
      res.status(500).json({
        status: 'error',
        message: 'Failed to mark arrival'
      });
    }
  }
);

// Resolve SOS
router.put(
  '/:sosId/resolve',
  authorize('guard', 'admin'),
  sosController.resolveSOS
);

// Upload evidence
router.post(
  '/:sosId/upload-evidence',
  authorize('guard', 'admin', 'resident'),
  sosController.uploadEvidence
);

// Police dashboard statistics
router.get(
  '/police/dashboard',
  authorize('admin'),
  sosController.getPoliceDashboard
);

// Offline SOS sync endpoint
router.post(
  '/offline-sync',
  authorize('resident', 'guard'),
  async (req, res) => {
    try {
      const { sosEvents } = req.body;

      if (!Array.isArray(sosEvents)) {
        return res.status(400).json({
          status: 'error',
          message: 'sosEvents must be an array'
        });
      }

      const synced = [];
      const failed = [];

      for (const event of sosEvents) {
        try {
          // Process offline SOS event
          const response = await sosController.triggerSOS({
            body: { ...event, isOffline: true },
            user: req.user
          }, null);

          synced.push(event.localId);
        } catch (error) {
          failed.push({ localId: event.localId, error: error.message });
        }
      }

      res.status(200).json({
        status: 'success',
        message: 'Offline SOS events synced',
        data: {
          synced: synced.length,
          failed: failed.length,
          syncedIds: synced,
          failedEvents: failed
        }
      });
    } catch (error) {
      res.status(500).json({
        status: 'error',
        message: 'Offline sync failed'
      });
    }
    // ================= POLICE ROUTES =================

// Police dashboard summary
router.get(
  '/police/dashboard',
  auth(['admin']),
  sosController.getPoliceDashboard
);

// Police map view (lat-long SOS)
router.get(
  '/police/map',
  auth(['admin']),
  sosController.getPoliceSOSMap
);
  }
);

module.exports = router;
