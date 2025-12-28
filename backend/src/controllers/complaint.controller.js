const Complaint = require('../models/Complaint');

// Create complaint
exports.createComplaint = async (req, res) => {
  try {
    const { type, description, flatNumber } = req.body;
    
    if (!type || !description) {
      return res.status(400).json({
        status: 'error',
        message: 'Type and description are required'
      });
    }

    const complaint = await Complaint.create({
      userId: req.user.id,
      userName: req.user.name || req.user.fullName || 'Unknown User',
      flatNumber: flatNumber || req.user.flatNumber,
      type,
      description,
      status: 'submitted'
    });

    console.log(`📝 Complaint created: ${complaint._id} by ${complaint.userName} - Type: ${type}`);

    res.status(201).json({
      status: 'success',
      message: 'Complaint submitted successfully',
      data: complaint
    });
  } catch (error) {
    console.error('Create complaint error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to create complaint'
    });
  }
};

// Get complaints
exports.getComplaints = async (req, res) => {
  try {
    const { mine } = req.query;
    
    let query = {};
    
    // Filter by logged-in user if mine=true
    if (mine === 'true') {
      query.userId = req.user.id;
    }

    const complaints = await Complaint.find(query).sort({ createdAt: -1 });

    res.json({
      status: 'success',
      data: complaints
    });
  } catch (error) {
    console.error('Get complaints error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get complaints'
    });
  }
};

// Get single complaint
exports.getComplaintById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const complaint = await Complaint.findById(id);

    if (!complaint) {
      return res.status(404).json({
        status: 'error',
        message: 'Complaint not found'
      });
    }

    // Residents can only view their own complaints
    if (req.user.role === 'resident' && complaint.userId !== req.user.id) {
      return res.status(403).json({
        status: 'error',
        message: 'Access denied'
      });
    }

    res.json({
      status: 'success',
      data: { complaint }
    });
  } catch (error) {
    console.error('Get complaint error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get complaint'
    });
  }
};

// Update complaint status (admin/guard only)
exports.updateComplaintStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolutionNotes } = req.body;
    
    if (!['open', 'in_progress', 'resolved', 'closed'].includes(status)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid status'
      });
    }

    const updateData = { status };
    if (status === 'resolved' || status === 'closed') {
      updateData.resolvedAt = new Date();
    }
    if (resolutionNotes) {
      updateData.resolutionNotes = resolutionNotes;
    }

    const complaint = await Complaint.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    );

    if (!complaint) {
      return res.status(404).json({
        status: 'error',
        message: 'Complaint not found'
      });
    }

    res.json({
      status: 'success',
      message: 'Complaint status updated',
      data: { complaint }
    });
  } catch (error) {
    console.error('Update complaint error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update complaint'
    });
  }
};
