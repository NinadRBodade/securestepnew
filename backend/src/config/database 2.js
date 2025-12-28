// Import mongoose
const mongoose = require('mongoose');

// Async function to connect DB
const connectDB = async () => {
  try {
    console.log('🔄 Connecting to MongoDB...');
    
    // Connect using URI from .env with timeout settings
    await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 5000, // 5 second timeout
      socketTimeoutMS: 10000,
    });

    // Success log
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    // Error log
    console.error('❌ MongoDB connection failed:', error.message);
    
    // Don't exit - let the app run without DB for now
    // This allows us to see other errors
  }
};

// Export function
module.exports = connectDB;