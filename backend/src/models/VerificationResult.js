const mongoose = require('mongoose');

const verificationResultSchema = new mongoose.Schema({
  // Reference to agent/document
  agentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Agent',
    required: true,
  },
  documentId: {
    type: String,
    required: true,
  },
  documentType: {
    type: String,
    enum: ['ID_CARD', 'PASSPORT', 'DRIVING_LICENSE', 'AADHAR', 'PAN', 'OTHER'],
    default: 'ID_CARD',
  },
  
  // OCR Results
  ocrResults: {
    fields: {
      name: String,
      id_number: String,
      dob: String,
      expiry_date: String,
      gender: String,
      address: String,
      document_type: String,
    },
    ocrConfidence: {
      type: Number,
      min: 0,
      max: 1,
    },
    qualityScore: Number,
    completeness: Number,
    rawText: String,
    wordCount: Number,
  },
  
  // Document Validation
  validation: {
    imageQuality: {
      width: Number,
      height: Number,
      format: String,
      aspectRatio: Number,
      resolutionValid: Boolean,
      brightnessValid: Boolean,
      sharpness: Number,
      qualityScore: Number,
    },
    templateValidation: {
      formatValid: Boolean,
      templateScore: Number,
      hasStructure: Boolean,
    },
    fieldValidation: {
      idNumber: {
        value: String,
        valid: Boolean,
      },
      dob: {
        value: String,
        valid: Boolean,
      },
      expiry: {
        value: String,
        valid: Boolean,
        expired: Boolean,
        daysRemaining: Number,
      },
      age: {
        valid: Boolean,
        age: Number,
      },
    },
    overallScore: Number,
    validationPassed: Boolean,
  },
  
  // Image Forensics
  forensics: {
    tampered: Boolean,
    tamperScore: Number,
    indicators: {
      copyPasteArtifacts: mongoose.Schema.Types.Mixed,
      blurInconsistencies: mongoose.Schema.Types.Mixed,
      sharpnessMismatch: mongoose.Schema.Types.Mixed,
      doubleJPEG: mongoose.Schema.Types.Mixed,
    },
    tamperedCount: Number,
  },
  
  // Metadata Analysis
  metadata: {
    metadataRisk: {
      type: String,
      enum: ['LOW', 'MEDIUM', 'HIGH'],
      default: 'LOW',
    },
    hasEditingSoftware: Boolean,
    isScreenshot: Boolean,
    hasCameraMetadata: Boolean,
    details: mongoose.Schema.Types.Mixed,
  },
  
  // Overall Risk Assessment
  riskScore: {
    type: Number,
    min: 0,
    max: 100,
    required: true,
  },
  riskLevel: {
    type: String,
    enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
    required: true,
  },
  recommendation: {
    type: String,
    enum: ['APPROVE', 'REVIEW', 'REJECT'],
    required: true,
  },
  
  // Admin Action
  adminDecision: {
    status: {
      type: String,
      enum: ['PENDING', 'APPROVED', 'REJECTED', 'OVERRIDDEN'],
      default: 'PENDING',
    },
    decidedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    decidedAt: Date,
    reason: String,
    notes: String,
  },
  
  // Verification Status
  verificationStatus: {
    type: String,
    enum: ['PROCESSING', 'COMPLETED', 'FAILED'],
    default: 'PROCESSING',
  },
  
  // Processing Info
  processingTime: Number, // in milliseconds
  verifiedAt: {
    type: Date,
    default: Date.now,
  },
  
  // Audit Trail
  history: [{
    action: String,
    performedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
    details: mongoose.Schema.Types.Mixed,
  }],
  
}, {
  timestamps: true,
});

// Indexes
verificationResultSchema.index({ agentId: 1 });
verificationResultSchema.index({ documentId: 1 });
verificationResultSchema.index({ riskLevel: 1 });
verificationResultSchema.index({ 'adminDecision.status': 1 });
verificationResultSchema.index({ verifiedAt: -1 });

// Methods
verificationResultSchema.methods.addHistoryEntry = function(action, userId, details) {
  this.history.push({
    action,
    performedBy: userId,
    details,
    timestamp: new Date(),
  });
  return this.save();
};

verificationResultSchema.methods.approve = function(userId, notes) {
  this.adminDecision = {
    status: 'APPROVED',
    decidedBy: userId,
    decidedAt: new Date(),
    notes,
  };
  return this.addHistoryEntry('APPROVED', userId, { notes });
};

verificationResultSchema.methods.reject = function(userId, reason) {
  this.adminDecision = {
    status: 'REJECTED',
    decidedBy: userId,
    decidedAt: new Date(),
    reason,
  };
  return this.addHistoryEntry('REJECTED', userId, { reason });
};

verificationResultSchema.methods.override = function(userId, reason, newDecision) {
  this.adminDecision = {
    status: 'OVERRIDDEN',
    decidedBy: userId,
    decidedAt: new Date(),
    reason,
  };
  this.recommendation = newDecision;
  return this.addHistoryEntry('OVERRIDDEN', userId, { reason, newDecision });
};

module.exports = mongoose.model('VerificationResult', verificationResultSchema);
