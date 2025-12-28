// Import mongoose
const mongoose = require('mongoose');

// Async function to connect DB
const connectDB = async () => {
  try {
    console.log('🔄 Connecting to MongoDB...');
    
    // Connect using URI from .env with longer timeout settings
    await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 30000, // 30 second timeout
      socketTimeoutMS: 45000,
      connectTimeoutMS: 30000,
    });

    // Success log
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    // Error log
    console.error('❌ MongoDB connection failed:', error.message);
    console.log('⚠️ Server will continue running but database operations will fail');
    console.log('💡 Please check:');
    console.log('   1. MongoDB Atlas is accessible from your network');
    console.log('   2. Your IP is whitelisted in MongoDB Atlas');
    console.log('   3. Username/password in .env are correct');
    
    // Don't exit - let the app run without DB for now
  }
};

// Export function
module.exports = connectDB;