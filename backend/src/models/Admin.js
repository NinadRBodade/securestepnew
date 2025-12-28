const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    accessLevel: {
      type: String,
      enum: ['society_admin', 'police_admin'],
      default: 'society_admin'
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Admin', adminSchema);