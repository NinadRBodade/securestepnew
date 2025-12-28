const Visit = require('../models/Visit');

exports.createVisit = async (req, res) => {
  const visit = await Visit.create(req.body);
  res.status(201).json({ status: 'success', data: visit });
};

exports.getVisits = async (req, res) => {
  const visits = await Visit.find().sort({ createdAt: -1 });
  res.json({ status: 'success', data: visits });
};

exports.getVisitById = async (req, res) => {
  const visit = await Visit.findById(req.params.visitId);
  res.json({ status: 'success', data: visit });
};

exports.markExit = async (req, res) => {
  const visit = await Visit.findByIdAndUpdate(
    req.params.visitId,
    { exitTime: new Date(), status: 'completed' },
    { new: true }
  );
  res.json({ status: 'success', data: visit });
};
