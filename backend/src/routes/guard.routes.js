const express = require('express');
const router = express.Router();
const guardController = require('../controllers/guard.controller');
const { protect, authorize } = require('../middleware/auth.middleware');

// All routes require guard authentication
router.use(protect);
router.use(authorize('guard'));

// QR Scan - Toggle entry/exit
router.post('/scan-agent', guardController.scanAgent);

// Sync offline entry (from mobile app)
router.post('/sync-offline-entry', guardController.syncOfflineEntry);

// Active agents (currently inside)
router.get('/active-agents', guardController.getActiveAgents);

// Entry/Exit logs
router.get('/entry-logs', guardController.getEntryLogs);

module.exports = router;
