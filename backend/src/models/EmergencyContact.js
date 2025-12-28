const mongoose = require('mongoose');

const emergencyContactSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
      index: true
    },
    
    name: {
      type: String,
      required: true
    },
    
    relation: {
      type: String,
      required: true
    },
    
    phone: {
      type: String,
      required: true
    }
  },
  { 
    timestamps: true 
  }
);

emergencyContactSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('EmergencyContact', emergencyContactSchema);
