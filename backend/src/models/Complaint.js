const mongoose = require('mongoose');

const complaintSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
      index: true
    },
    
    userName: {
      type: String,
      required: true
    },
    
    flatNumber: String,
    
    type: {
      type: String,
      enum: ['guard_misbehaviour', 'agent_suspicious', 'maintenance', 'noise_rules', 'unknown_visitors'],
      required: true
    },
    
    description: {
      type: String,
      required: true
    },
    
    status: {
      type: String,
      enum: ['submitted', 'reviewed', 'resolved'],
      default: 'submitted'
    },
    
    resolvedAt: Date,
    resolutionNotes: String
  },
  { 
    timestamps: true 
  }
);

complaintSchema.index({ userId: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model('Complaint', complaintSchema);
