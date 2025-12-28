const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required']
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      select: false
    },
    phone: {
      type: String,
      required: false
    },
    role: {
      type: String,
      enum: ['resident', 'agent', 'guard', 'admin', 'police'],
      default: 'resident'
    },
    societyId: {
      type: String,
      required: false
    },
    flatNumber: {
      type: String,
      required: false
    },
    emergencyPreference: {
      type: String,
      enum: ['push', 'sms', 'both'],
      default: 'both'
    },
    isActive: {
      type: Boolean,
      default: true
    }
  },
  { 
    timestamps: true 
  }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
