const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const FaceData = require('../models/FaceData');

// Configure multer for face image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads/faces');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const userEmail = req.body.email || 'unknown';
    const sanitizedEmail = userEmail.replace(/[^a-zA-Z0-9]/g, '_');
    cb(null, `${sanitizedEmail}_${Date.now()}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (extname && mimetype) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, JPG, and PNG images are allowed'));
    }
  }
});

// Upload face image
router.post('/upload', upload.single('faceImage'), async (req, res) => {
  try {
    const { email, role } = req.body;
    
    if (!email || !role) {
      return res.status(400).json({ error: 'Email and role are required' });
    }
    
    if (!req.file) {
      return res.status(400).json({ error: 'Face image is required' });
    }
    
    // Check if face already exists and delete old file
    const existingFace = await FaceData.findOne({ email });
    if (existingFace) {
      // Delete old file if exists
      if (fs.existsSync(existingFace.imagePath)) {
        fs.unlinkSync(existingFace.imagePath);
        console.log('🗑️ Deleted old face image:', existingFace.filename);
      }
    }
    
    // Save to MongoDB
    const faceDataDoc = await FaceData.findOneAndUpdate(
      { email },
      {
        email: email.toLowerCase(),
        role,
        imagePath: req.file.path,
        filename: req.file.filename,
        uploadedAt: new Date(),
        imageSize: req.file.size,
        mimeType: req.file.mimetype,
        isActive: true
      },
      { upsert: true, new: true }
    );
    
    console.log('✅ Face uploaded to MongoDB for:', email);
    
    res.json({
      success: true,
      message: 'Face image uploaded successfully',
      data: {
        email: faceDataDoc.email,
        filename: faceDataDoc.filename,
        uploadedAt: faceDataDoc.uploadedAt
      }
    });
  } catch (error) {
    console.error('❌ Face upload error:', error);
    // Clean up uploaded file if database save failed
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ error: error.message });
  }
});

// Get face image
router.get('/image/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const face = await FaceData.findOne({ 
      email: email.toLowerCase(), 
      isActive: true 
    });
    
    if (!face) {
      return res.status(404).json({ error: 'Face not found for this user' });
    }
    
    // Check if file exists
    if (!fs.existsSync(face.imagePath)) {
      console.error('❌ Face file not found:', face.imagePath);
      return res.status(404).json({ error: 'Face image file not found' });
    }
    
    // Send the image file
    res.sendFile(path.resolve(face.imagePath));
  } catch (error) {
    console.error('❌ Face retrieval error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Check if face is registered
router.get('/check/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const face = await FaceData.findOne({ 
      email: email.toLowerCase(), 
      isActive: true 
    });
    
    res.json({
      registered: !!face,
      email,
      uploadedAt: face?.uploadedAt || null,
      role: face?.role || null
    });
  } catch (error) {
    console.error('❌ Face check error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete face image
router.delete('/delete/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const face = await FaceData.findOne({ email: email.toLowerCase() });
    
    if (!face) {
      return res.status(404).json({ error: 'Face not found' });
    }
    
    // Delete file if exists
    if (fs.existsSync(face.imagePath)) {
      fs.unlinkSync(face.imagePath);
      console.log('🗑️ Deleted face image file:', face.filename);
    }
    
    // Remove from MongoDB
    await FaceData.deleteOne({ email: email.toLowerCase() });
    console.log('✅ Face data deleted from MongoDB');
    
    res.json({
      success: true,
      message: 'Face image deleted successfully'
    });
  } catch (error) {
    console.error('❌ Face deletion error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all registered faces (for admin/debug)
router.get('/all', async (req, res) => {
  try {
    const { role } = req.query;
    const filter = { isActive: true };
    
    if (role) {
      filter.role = role;
    }
    
    const faces = await FaceData.find(filter)
      .select('-imagePath') // Don't expose file paths
      .sort({ uploadedAt: -1 });
    
    res.json({
      success: true,
      count: faces.length,
      data: faces.map(f => ({
        email: f.email,
        role: f.role,
        uploadedAt: f.uploadedAt,
        filename: f.filename
      }))
    });
  } catch (error) {
    console.error('❌ Error fetching faces:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
