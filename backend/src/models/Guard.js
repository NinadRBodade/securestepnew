const mongoose = require('mongoose');

const guardSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    phone: {
        type: String
    },
    societyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Society',
        required: true
    },
    password: {
        type: String,
        required: true
    },
    tempPassword: {
        type: String
    },
    active: {
        type: Boolean,
        default: true
    },
    role: {
        type: String,
        default: 'guard'
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Guard', guardSchema);
