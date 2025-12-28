const mongoose = require('mongoose');

const residentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    societyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Society',
      required: true
    },

    flatNumber: {
      type: String,
      required: true
    },

    isOwner: {
      type: Boolean,
      default: true
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Resident', residentSchema);