const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ message: 'Blockchain routes' });
});

module.exports = router;
