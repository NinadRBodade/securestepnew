const mongoose = require('mongoose');

const sosEventSchema = new mongoose.Schema(
  {
    // Custom SOS ID (frontend-facing)
    sosId: {
      type: String,
      unique: true,
      index: true
    },
    
    // User who triggered SOS
    userId: {
      type: String,
      required: true
    },
    
    userName: {
      type: String,
      required: true
    },
    
    userRole: {
      type: String,
      required: true,
      enum: ['agent', 'resident', 'guard', 'admin']
    },
    
    flatNumber: String,
    
    // Triggered timestamp (immutable - used for blockchain hash)
    triggeredAt: Date,
    
    // Location data
    latitude: String,
    longitude: String,
    locationAddress: String,
    
    // Status workflow
    status: {
      type: String,
      enum: ['active', 'acknowledged', 'resolved', 'false_alarm', 'triggered', 'arrived'],
      default: 'active'
    },
    
    // Agent context (if agent present during emergency)
    agentId: String,
    agentName: String,
    agentCompany: String,
    
    // Emergency details
    description: String,
    photoPath: String,
    
    // Guard response tracking
    guardId: String,
    guardArrivedAt: Date,
    acknowledgedAt: Date,
    resolvedAt: Date,
    resolutionNotes: String,
    
    // Sync status
    isSynced: {
      type: Boolean,
      default: true
    },
    
    // Blockchain integration
    blockchainHash: String
  },
  { 
    timestamps: true 
  }
);

// Index for faster queries
sosEventSchema.index({ sosId: 1 });
sosEventSchema.index({ status: 1, createdAt: -1 });
sosEventSchema.index({ userId: 1 });
sosEventSchema.index({ guardId: 1 });

module.exports = mongoose.model('SOSEvent', sosEventSchema);