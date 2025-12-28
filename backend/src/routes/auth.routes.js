const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { validateRegistration, validateLogin } = require('../middleware/validation.middleware');
const User = require('../models/User');
const Guard = require('../models/Guard');
const Agent = require('../models/Agent');
const guardAuthController = require('../controllers/guard.auth.controller');

// Register
router.post('/register', validateRegistration, async (req, res) => {
  try {
    const { name, email, password, role, phoneNumber, phone, societyId, flatNumber } = req.body;
    
    const userPhone = phoneNumber || phone || '';
    
    // Check if user with email already exists in ANY collection
    const existingUser = await User.findOne({ email });
    const existingAgent = await Agent.findOne({ email });
    const existingGuard = await Guard.findOne({ email });
    
    if (existingUser) {
      console.log('❌ Registration failed - email exists in User collection:', email);
      // For development: Delete and re-register
      await User.deleteOne({ email });
      console.log('🗑️ Deleted existing user, allowing re-registration');
    }
    
    if (existingAgent) {
      console.log('❌ Registration failed - email exists in Agent collection:', email);
      return res.status(400).json({
        success: false,
        message: 'This email is already registered as an agent. Please use agent portal.'
      });
    }
    
    if (existingGuard) {
      console.log('❌ Registration failed - email exists in Guard collection:', email);
      return res.status(400).json({
        success: false,
        message: 'This email is registered as a guard. Please use guard login.'
      });
    }
    
    // Check if user with phone already exists (if phone provided)
    if (userPhone) {
      const existingPhone = await User.findOne({ phone: userPhone });
      if (existingPhone) {
        return res.status(400).json({
          success: false,
          message: 'User already registered. Please login.'
        });
      }
    }
    
    // Create user in MongoDB
    const user = await User.create({
      name,
      email,
      password, // Will be hashed by pre-save hook
      role: role || 'resident',
      phone: userPhone,
      societyId: societyId || `SOC${Math.abs(email.split('').reduce((a,c)=>a+c.charCodeAt(0),0)) % 1000}`,
      flatNumber: flatNumber || `A-${Math.abs(email.split('').reduce((a,c)=>a+c.charCodeAt(0),0)) % 500 + 100}`
    });
    
    console.log('✅ User registered in MongoDB:', email, 'Role:', user.role);
    
    // Generate JWT token with all user info
    const token = jwt.sign(
      { 
        id: user._id.toString(), 
        role: user.role,
        name: user.name,
        email: user.email,
        phone: user.phone,
        societyId: user.societyId,
        flatNumber: user.flatNumber
      },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '7d' }
    );
    
    res.status(201).json({
      success: true,
      status: 'success',
      message: 'Registration successful',
      token: token,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        societyId: user.societyId,
        flatNumber: user.flatNumber
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Login
router.post('/login', validateLogin, async (req, res) => {
  try {
    const { email, phone, password } = req.body;
    
    // First, try to find in Agent collection if email is provided (agents don't have passwords, email-only)
    if (email && !password) {
      const agent = await Agent.findOne({ email });
      
      if (agent) {
        console.log('✅ Agent logged in (email-only):', email);
        
        // Generate JWT token for agent
        const token = jwt.sign(
          { 
            id: agent._id.toString(), 
            role: 'agent',
            name: agent.name,
            email: agent.email,
            phone: agent.phone || '',
            company: agent.company || '',
            verified: agent.verified || false
          },
          process.env.JWT_SECRET || 'fallback-secret',
          { expiresIn: '7d' }
        );
        
        return res.json({
          success: true,
          status: 'success',
          message: 'Login successful',
          token: token,
          user: {
            id: agent._id.toString(),
            name: agent.name,
            email: agent.email,
            role: 'agent',
            phone: agent.phone || '',
            company: agent.company || '',
            verified: agent.verified || false
          }
        });
      }
    }
    
    // Second, try to find in Guard collection if email is provided
    if (email) {
      const guard = await Guard.findOne({ email }).populate('societyId', 'name societyId');
      
      if (guard) {
        // Check if guard is active
        if (!guard.active) {
          return res.status(403).json({
            success: false,
            message: 'Your guard account has been deactivated. Please contact your society admin.'
          });
        }
        
        // Check password
        const isValid = await bcrypt.compare(password, guard.password);
        if (!isValid) {
          return res.status(401).json({
            success: false,
            message: 'Invalid credentials'
          });
        }
        
        console.log('✅ Guard logged in from MongoDB:', email, 'Society:', guard.societyId?.name);
        
        // Generate JWT token for guard
        const token = jwt.sign(
          { 
            id: guard._id.toString(), 
            role: 'guard',
            name: guard.name,
            email: guard.email,
            phone: guard.phone,
            societyId: guard.societyId?._id?.toString() || guard.societyId,
            societyName: guard.societyId?.name || ''
          },
          process.env.JWT_SECRET || 'fallback-secret',
          { expiresIn: '7d' }
        );
        
        return res.json({
          success: true,
          status: 'success',
          message: 'Login successful',
          token: token,
          user: {
            id: guard._id.toString(),
            name: guard.name,
            email: guard.email,
            role: 'guard',
            phone: guard.phone,
            societyId: guard.societyId?._id?.toString() || guard.societyId,
            societyName: guard.societyId?.name || ''
          }
        });
      }
    }
    
    // If not found in Guard collection, check User collection
    let user;
    if (email) {
      user = await User.findOne({ email }).select('+password');
    } else if (phone) {
      user = await User.findOne({ phone }).select('+password');
    }
    
    if (!user) {
      console.log('❌ Login failed - user not found:', email || phone);
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    console.log('🔍 User found in DB:', email || phone, 'Role:', user.role, 'Has password:', !!user.password);
    
    // Check password using model method
    const isValid = await user.comparePassword(password);
    if (!isValid) {
      console.log('❌ Login failed - password mismatch for:', email || phone);
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    console.log('✅ User logged in from MongoDB:', email || phone, 'Role:', user.role);
    
    // Generate JWT token with all user info
    const token = jwt.sign(
      { 
        id: user._id.toString(), 
        role: user.role,
        name: user.name,
        email: user.email,
        phone: user.phone,
        societyId: user.societyId,
        flatNumber: user.flatNumber
      },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '7d' }
    );
    
    res.json({
      success: true,
      status: 'success',
      message: 'Login successful',
      token: token,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        societyId: user.societyId,
        flatNumber: user.flatNumber
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
});

// Verify JWT token
router.get('/verify', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'No token provided'
      });
    }
    
    // Verify JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret');
    
    // Find user in MongoDB to ensure they still exist
    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }
    
    console.log('✅ Token verified for:', user.email, 'Role:', user.role);
    
    res.json({
      success: true,
      message: 'Token valid',
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        societyId: user.societyId,
        flatNumber: user.flatNumber
      }
    });
  } catch (error) {
    console.error('Token verification error:', error.message);
    res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
});

// Guard credential request - Check if guard exists and send credentials via email
router.post('/guard/request-credentials', guardAuthController.requestGuardCredentials);

module.exports = router;
