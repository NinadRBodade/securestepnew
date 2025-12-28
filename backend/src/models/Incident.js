const mongoose = require('mongoose');

const incidentSchema = new mongoose.Schema({
  reportedBy: { type: String, required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  flatNumber: { type: String },
  societyId: { type: String, required: true },
  severity: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' },
  status: { type: String, enum: ['open', 'investigating', 'resolved'], default: 'open' }
}, { timestamps: true });

module.exports = mongoose.model('Incident', incidentSchema);
