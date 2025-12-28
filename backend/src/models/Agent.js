const mongoose = require('mongoose');

const agentSchema = new mongoose.Schema({
  id: { type: String, unique: true, sparse: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String },
  company: { type: String },
  serviceType: { type: String },
  verified: { type: Boolean, default: false },
  score: { type: Number, default: 0 },
  isInside: { type: Boolean, default: false },
  lastCheckIn: { type: Date },
  lastCheckOut: { type: Date },
  documentsUploaded: { type: Boolean, default: false },
  uploadedAt: { type: Date },
  qrData: { type: String },
  photo: { type: String },
  idProof: { type: String },
  certificate: { type: String },
  rejected: { type: Boolean, default: false },
  rejectionReason: { type: String },
  rejectedAt: { type: Date },
  verificationNotes: { type: String },
  notificationSettings: {
    entryExit: { type: Boolean, default: true },
    verification: { type: Boolean, default: true }
  }
}, { timestamps: true });

module.exports = mongoose.model('Agent', agentSchema);
