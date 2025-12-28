const mongoose = require('mongoose');

const faceDataSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      trim: true,
      lowercase: true,
      index: true
    },
    role: {
      type: String,
      enum: ['agent', 'resident', 'guard'],
      required: [true, 'Role is required']
    },
    imagePath: {
      type: String,
      required: [true, 'Image path is required']
    },
    filename: {
      type: String,
      required: [true, 'Filename is required']
    },
    uploadedAt: {
      type: Date,
      default: Date.now
    },
    isActive: {
      type: Boolean,
      default: true
    },
    // Additional metadata
    imageSize: {
      type: Number // in bytes
    },
    mimeType: {
      type: String
    }
  },
  { 
    timestamps: true 
  }
);

// Index for faster queries
faceDataSchema.index({ email: 1, isActive: 1 });
faceDataSchema.index({ role: 1, isActive: 1 });

// Method to get public data (without sensitive paths)
faceDataSchema.methods.getPublicData = function() {
  return {
    email: this.email,
    role: this.role,
    filename: this.filename,
    uploadedAt: this.uploadedAt,
    isActive: this.isActive
  };
};

module.exports = mongoose.model('FaceData', faceDataSchema);
