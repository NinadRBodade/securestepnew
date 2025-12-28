const jwt = require('jsonwebtoken');
const User = require('../models/User');

const signToken = (user) =>
  jwt.sign(
    { 
      id: user._id, 
      role: user.role,
      name: user.name || user.fullName,
      email: user.email,
      phone: user.phone || user.mobile,
      societyId: user.societyId,
      flatNumber: user.flatNumber
    },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

exports.register = async (req, res) => {
  try {
    // Prevent guard registration via mobile app
    if (req.body.role === 'guard') {
      return res.status(403).json({
        status: 'error',
        message: 'Guards cannot register directly. Please contact your society admin.'
      });
    }

    // Prevent admin registration via mobile app
    if (req.body.role === 'admin') {
      return res.status(403).json({
        status: 'error',
        message: 'Admin accounts cannot be created via registration.'
      });
    }

    const user = await User.create(req.body);
    const token = signToken(user);

    res.status(201).json({
      status: 'success',
      data: { user, token },
      token: token
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(400).json({
      status: 'error',
      message: error.message || 'Registration failed'
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select('+password');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid email or password'
      });
    }

    const token = signToken(user);

    res.json({
      status: 'success',
      data: { user, token }
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Login failed'
    });
  }
};