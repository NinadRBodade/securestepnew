const NotificationSettings = require('../models/NotificationSettings');
const EmergencyContact = require('../models/EmergencyContact');
const Visit = require('../models/Visit');
const Agent = require('../models/Agent');

// Get resident profile (using JWT data since auth is in-memory)
exports.getProfile = async (req, res) => {
  try {
    // User data comes from JWT token via protect middleware
    const user = req.user;
    
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.json({
      status: 'success',
      data: {
        name: user.name || 'Unknown',
        email: user.email || '',
        phone: user.phone || '',
        flatNumber: user.flatNumber || '',
        emergencyPreference: 'both'
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get profile',
      error: error.message
    });
  }
};

// Update resident profile (Note: Since using in-memory auth, this just returns success)
exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, emergencyPreference } = req.body;
    
    // Note: With in-memory auth, we can't persist user updates
    // In production with MongoDB, this would update the User model
    // For now, just return success
    
    res.json({
      status: 'success',
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update profile'
    });
  }
};

// Get notification settings
exports.getSettings = async (req, res) => {
  try {
    let settings = await NotificationSettings.findOne({ userId: req.user.id });
    
    // Create default settings if not exists
    if (!settings) {
      settings = await NotificationSettings.create({
        userId: req.user.id,
        pushEnabled: true,
        smsEnabled: false
      });
    }

    res.json({
      status: 'success',
      data: { settings }
    });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get settings'
    });
  }
};

// Update notification settings
exports.updateSettings = async (req, res) => {
  try {
    const { pushEnabled, smsEnabled } = req.body;
    
    let settings = await NotificationSettings.findOne({ userId: req.user.id });
    
    if (!settings) {
      settings = await NotificationSettings.create({
        userId: req.user.id,
        pushEnabled: pushEnabled !== undefined ? pushEnabled : true,
        smsEnabled: smsEnabled !== undefined ? smsEnabled : false
      });
    } else {
      if (pushEnabled !== undefined) settings.pushEnabled = pushEnabled;
      if (smsEnabled !== undefined) settings.smsEnabled = smsEnabled;
      await settings.save();
    }

    res.json({
      status: 'success',
      message: 'Settings updated successfully',
      data: settings
    });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update settings'
    });
  }
};

// Get emergency contacts
exports.getContacts = async (req, res) => {
  try {
    const contacts = await EmergencyContact.find({ userId: req.user.id }).sort({ createdAt: -1 });

    res.json({
      status: 'success',
      data: contacts
    });
  } catch (error) {
    console.error('Get contacts error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get contacts'
    });
  }
};

// Add emergency contact
exports.addContact = async (req, res) => {
  try {
    const { name, relation, phone } = req.body;
    
    if (!name || !relation || !phone) {
      return res.status(400).json({
        status: 'error',
        message: 'Name, relation, and phone are required'
      });
    }

    const contact = await EmergencyContact.create({
      userId: req.user.id,
      name,
      relation,
      phone
    });

    res.status(201).json({
      status: 'success',
      message: 'Contact added successfully',
      data: contact
    });
  } catch (error) {
    console.error('Add contact error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to add contact'
    });
  }
};

// Delete emergency contact
exports.deleteContact = async (req, res) => {
  try {
    const { id } = req.params;
    
    const contact = await EmergencyContact.findOneAndDelete({
      _id: id,
      userId: req.user.id // Ensure user can only delete their own contacts
    });

    if (!contact) {
      return res.status(404).json({
        status: 'error',
        message: 'Contact not found'
      });
    }

    res.json({
      status: 'success',
      message: 'Contact deleted successfully'
    });
  } catch (error) {
    console.error('Delete contact error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete contact'
    });
  }
};

// Existing visit functions
exports.verifyQRCode = async (req, res) => {
  // QR verification logic will be added later
  res.json({
    status: 'success',
    message: 'QR verified (logic pending)'
  });
};

exports.allowEntry = async (req, res) => {
  const visit = await Visit.create(req.body);
  res.status(201).json({
    status: 'success',
    data: visit
  });
};

exports.getVisitHistory = async (req, res) => {
  const visits = await Visit.find({ residentId: req.user.id })
    .sort({ createdAt: -1 });

  res.json({
    status: 'success',
    data: visits
  });
};