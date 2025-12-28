const express = require('express');
const router = express.Router();
const Society = require('../models/Society');
const societyController = require('../controllers/society.controller');

// Get all active societies (for dropdown)
router.get('/list', async (req, res) => {
  try {
    console.log('📋 Fetching society list for user dropdown...');
    
    const societies = await Society.find({ isActive: true })
      .select('_id name address city state')
      .sort({ name: 1 })
      .lean();
    
    console.log(`✅ Found ${societies.length} active societies`);
    
    res.json({
      success: true,
      societies: societies,
      count: societies.length
    });
  } catch (error) {
    console.error('❌ Error fetching societies:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch societies',
      error: error.message,
      societies: []
    });
  }
});

// Admin routes for society management
router.get('/', societyController.getAllSocieties);
router.post('/', societyController.createSociety);
router.get('/:societyId', societyController.getSociety);
router.put('/:societyId', societyController.updateSociety);
router.get('/:societyId/guards', societyController.getSocietyGuards);
router.get('/:societyId/residents', societyController.getResidents);

// Legacy create route (for backward compatibility)
router.post('/create', async (req, res) => {
  try {
    const { name, address, city, state, pincode, totalFlats } = req.body;
    
    const society = await Society.create({
      name,
      address,
      city,
      state,
      pincode,
      totalFlats
    });
    
    res.status(201).json({
      success: true,
      message: 'Society created successfully',
      society
    });
  } catch (error) {
    console.error('Error creating society:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
