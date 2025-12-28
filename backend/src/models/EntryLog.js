const mongoose = require('mongoose');

const entryLogSchema = new mongoose.Schema({
  agentId: { type: String, required: true },
  name: { type: String, required: true },
  company: { type: String },
  action: { type: String, enum: ['CHECK_IN', 'CHECK_OUT'], required: true },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('EntryLog', entryLogSchema);
