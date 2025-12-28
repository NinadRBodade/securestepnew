const mongoose = require('mongoose');

const visitSchema = new mongoose.Schema({
  personType: { type: String, enum: ['agent', 'guest'], default: 'agent' },
  agentId: { type: String },
  name: { type: String, required: true },
  phone: { type: String },
  company: { type: String },
  purpose: { type: String },
  flatNumber: { type: String },
  societyId: { type: String, required: true },
  entryTime: { type: Date, default: Date.now },
  exitTime: { type: Date },
  status: { type: String, enum: ['active', 'completed'], default: 'active' },
  verifiedBy: { type: String }
}, { timestamps: true });

module.exports = mongoose.model('Visit', visitSchema);
