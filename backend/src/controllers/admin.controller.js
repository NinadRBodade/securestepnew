const Agent = require('../models/Agent');

exports.getPendingAgents = async (req, res) => {
  const agents = await Agent.find({ verificationStatus: 'pending' });
  res.json({ status: 'success', data: agents });
};

exports.getVerifiedAgents = async (req, res) => {
  const agents = await Agent.find({ verificationStatus: 'verified' });
  res.json({ status: 'success', data: agents });
};

exports.approveAgent = async (req, res) => {
  const agent = await Agent.findOneAndUpdate(
    { agentId: req.params.agentId },
    { verificationStatus: 'verified' },
    { new: true }
  );
  res.json({ status: 'success', data: agent });
};

exports.rejectAgent = async (req, res) => {
  const agent = await Agent.findOneAndUpdate(
    { agentId: req.params.agentId },
    { verificationStatus: 'rejected' },
    { new: true }
  );
  res.json({ status: 'success', data: agent });
};

exports.updateSafetyScore = async (req, res) => {
  const agent = await Agent.findOneAndUpdate(
    { agentId: req.params.agentId },
    { safetyScore: req.body.score },
    { new: true }
  );
  res.json({ status: 'success', data: agent });
};
