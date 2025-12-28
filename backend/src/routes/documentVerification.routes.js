const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const verificationController = require('../controllers/documentVerification.controller');

// Configure multer for document uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/documents/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'doc-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|pdf/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (extname && mimetype) {
      return cb(null, true);
    } else {
      cb(new Error('Only images (JPG, PNG) and PDF files are allowed'));
    }
  }
});

// Verify document
router.post('/verify', upload.single('document'), verificationController.verifyDocument);

// Get verification result by ID
router.get('/result/:id', verificationController.getVerificationResult);

// Get all pending verifications
router.get('/pending', verificationController.getPendingVerifications);

// Approve verification
router.post('/approve/:id', verificationController.approveVerification);

// Reject verification
router.post('/reject/:id', verificationController.rejectVerification);

// Get verification stats
router.get('/stats', verificationController.getVerificationStats);

module.exports = router;
