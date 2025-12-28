exports.getProfile = async (req, res) => {
  res.json({ status: 'success', message: 'Agent profile - Coming soon' });
};

exports.updateProfile = async (req, res) => {
  res.json({ status: 'success', message: 'Update profile - Coming soon' });
};

exports.getSafetyScore = async (req, res) => {
  res.json({ status: 'success', data: { score: 100 } });
};
