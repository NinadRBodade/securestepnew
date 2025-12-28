const Guard = require('../models/Guard');
const Society = require('../models/Society');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

// Generate random password
function generatePassword() {
    return crypto.randomBytes(4).toString('hex');
}

// Create guard with auto-generated credentials
exports.createGuard = async (req, res) => {
    try {
        const { name, email, phone, societyId } = req.body;
        
        // Validate required fields
        if (!name || !email || !societyId) {
            return res.status(400).json({
                success: false,
                error: 'Name, email, and societyId are required'
            });
        }
        
        // Check if society exists
        const society = await Society.findById(societyId);
        if (!society) {
            return res.status(404).json({
                success: false,
                error: 'Society not found'
            });
        }
        
        // Check if guard already exists
        const existingGuard = await Guard.findOne({ email });
        if (existingGuard) {
            return res.status(400).json({
                success: false,
                error: 'Guard with this email already exists'
            });
        }
        
        // Generate temporary password
        const tempPassword = generatePassword();
        const hashedPassword = await bcrypt.hash(tempPassword, 10);
        
        // Create guard
        const guard = new Guard({
            name,
            email,
            phone,
            societyId,
            password: hashedPassword,
            tempPassword,
            active: true
        });
        
        await guard.save();
        
        // Update society guard count
        society.guardCount = (society.guardCount || 0) + 1;
        await society.save();
        
        // TODO: Send email with credentials
        console.log(`
========================================
NEW GUARD CREDENTIALS
========================================
Name: ${name}
Email: ${email}
Password: ${tempPassword}
Society: ${society.name}
========================================
IMPORTANT: Change password on first login
        `);
        
        res.status(201).json({
            success: true,
            message: 'Guard created successfully. Credentials sent via email.',
            guard: {
                _id: guard._id,
                name: guard.name,
                email: guard.email,
                phone: guard.phone,
                societyId: guard.societyId,
                active: guard.active
            },
            tempPassword // Only send in development, remove in production
        });
    } catch (error) {
        console.error('Create guard error:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to create guard'
        });
    }
};

// Get all guards
exports.getAllGuards = async (req, res) => {
    try {
        const guards = await Guard.find()
            .populate('societyId', 'name societyId')
            .select('-password -tempPassword')
            .sort({ createdAt: -1 });
        
        res.json({
            success: true,
            guards
        });
    } catch (error) {
        console.error('Get guards error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch guards'
        });
    }
};

// Update guard status
exports.updateGuardStatus = async (req, res) => {
    try {
        const { active } = req.body;
        
        const guard = await Guard.findByIdAndUpdate(
            req.params.id,
            { active },
            { new: true }
        ).select('-password -tempPassword');
        
        if (!guard) {
            return res.status(404).json({
                success: false,
                error: 'Guard not found'
            });
        }
        
        res.json({
            success: true,
            message: `Guard ${active ? 'enabled' : 'disabled'} successfully`,
            guard
        });
    } catch (error) {
        console.error('Update guard status error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update guard status'
        });
    }
};
