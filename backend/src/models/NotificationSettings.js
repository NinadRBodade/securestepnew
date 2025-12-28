const mongoose = require('mongoose');

const notificationSettingsSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
      unique: true,
      index: true
    },
    
    pushEnabled: {
      type: Boolean,
      default: true
    },
    
    smsEnabled: {
      type: Boolean,
      default: false
    }
  },
  { 
    timestamps: true 
  }
);

module.exports = mongoose.model('NotificationSettings', notificationSettingsSchema);
