const mongoose = require('mongoose');

const societySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Society name is required'],
      trim: true
    },
    societyId: {
      type: String,
      unique: true
    },
    address: {
      type: String,
      required: false
    },
    city: {
      type: String,
      required: false
    },
    state: {
      type: String,
      required: false
    },
    pincode: {
      type: String,
      required: false
    },
    totalFlats: {
      type: Number,
      default: 0
    },
    guardCount: {
      type: Number,
      default: 0
    },
    isActive: {
      type: Boolean,
      default: true
    }
  },
  { timestamps: true }
);

// Auto-generate societyId before save
societySchema.pre('save', async function(next) {
  if (!this.societyId) {
    // Generate format: SOC-YYYY-XXXX (e.g., SOC-2024-0001)
    const year = new Date().getFullYear();
    const count = await this.constructor.countDocuments();
    this.societyId = `SOC-${year}-${String(count + 1).padStart(4, '0')}`;
  }
  next();
});

module.exports = mongoose.model('Society', societySchema);