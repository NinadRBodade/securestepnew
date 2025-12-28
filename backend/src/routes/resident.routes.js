const express = require('express');
const router = express.Router();
const residentController = require('../controllers/resident.controller');
const { protect } = require('../middleware/auth.middleware');
const { validateProfileUpdate, validateEmergencyContact } = require('../middleware/validation.middleware');

// All routes require authentication
router.use(protect);

// Profile management
router.get('/profile', residentController.getProfile);
router.put('/profile', validateProfileUpdate, residentController.updateProfile);

// Notification settings
router.get('/settings', residentController.getSettings);
router.put('/settings', residentController.updateSettings);

// Emergency contacts
router.get('/contacts', residentController.getContacts);
router.post('/contacts', validateEmergencyContact, residentController.addContact);
router.delete('/contacts/:id', residentController.deleteContact);

// Visit history (existing functionality)
router.get('/visits', residentController.getVisitHistory);
router.post('/allow-entry', residentController.allowEntry);
router.post('/verify-qr', residentController.verifyQRCode);

module.exports = router;
