const express = require('express');
const router = express.Router();
const complaintController = require('../controllers/complaint.controller');
const { protect, authorize } = require('../middleware/auth.middleware');

// All routes require authentication
router.use(protect);

// Complaint routes
router.post('/', complaintController.createComplaint);
router.get('/', complaintController.getComplaints);
router.get('/:id', complaintController.getComplaintById);

// Admin/Guard only - update complaint status
router.put('/:id/status', authorize(['admin', 'guard']), complaintController.updateComplaintStatus);

module.exports = router;
