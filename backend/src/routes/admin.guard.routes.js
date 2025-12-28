const express = require('express');
const router = express.Router();
const adminGuardController = require('../controllers/admin.guard.controller');

// Admin guard management routes (no auth for now)
router.post('/create', adminGuardController.createGuard);
router.get('/', adminGuardController.getAllGuards);
router.put('/:id/status', adminGuardController.updateGuardStatus);

module.exports = router;
