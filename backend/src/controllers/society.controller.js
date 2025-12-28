const Society = require('../models/Society');
const Resident = require('../models/Resident');
const Guard = require('../models/Guard');

// Create new society
exports.createSociety = async (req, res) => {
  try {
    const { name, address, city, state, pincode } = req.body;
    
    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'Society name is required'
      });
    }
    
    const society = await Society.create({
      name,
      address,
      city,
      state,
      pincode
    });
    
    res.status(201).json({ 
      success: true,
      message: 'Society created successfully',
      society 
    });
  } catch (error) {
    console.error('Create society error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to create society'
    });
  }
};

// Get all societies
exports.getAllSocieties = async (req, res) => {
  try {
    const societies = await Society.find().sort({ createdAt: -1 });
    
    // Update guard counts
    for (let society of societies) {
      const guardCount = await Guard.countDocuments({ societyId: society._id });
      society.guardCount = guardCount;
      await society.save();
    }
    
    res.json({
      success: true,
      societies
    });
  } catch (error) {
    console.error('Get societies error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch societies'
    });
  }
};

exports.getSociety = async (req, res) => {
  try {
    const society = await Society.findById(req.params.societyId);
    
    if (!society) {
      return res.status(404).json({
        success: false,
        error: 'Society not found'
      });
    }
    
    // Update guard count
    const guardCount = await Guard.countDocuments({ societyId: society._id });
    society.guardCount = guardCount;
    await society.save();
    
    res.json({ 
      success: true,
      society 
    });
  } catch (error) {
    console.error('Get society error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch society'
    });
  }
};

exports.updateSociety = async (req, res) => {
  try {
    const { name, address, city, state, pincode } = req.body;
    
    const society = await Society.findByIdAndUpdate(
      req.params.societyId,
      { name, address, city, state, pincode },
      { new: true }
    );
    
    if (!society) {
      return res.status(404).json({
        success: false,
        error: 'Society not found'
      });
    }
    
    res.json({ 
      success: true,
      message: 'Society updated successfully',
      society 
    });
  } catch (error) {
    console.error('Update society error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update society'
    });
  }
};

// Get guards for a society
exports.getSocietyGuards = async (req, res) => {
  try {
    const guards = await Guard.find({ societyId: req.params.societyId })
      .select('-password -tempPassword')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      guards
    });
  } catch (error) {
    console.error('Get society guards error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch guards'
    });
  }
};

exports.getResidents = async (req, res) => {
  try {
    const residents = await Resident.find({
      societyId: req.params.societyId
    });
    res.json({ status: 'success', data: residents });
  } catch (error) {
    console.error('Get residents error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch residents'
    });
  }
};
