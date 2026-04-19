const { MongoMemoryServer } = require('mongodb-memory-server');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, 'dbdata');
if (!fs.existsSync(dbPath)) {
  fs.mkdirSync(dbPath);
}

(async () => {
  console.log('Staring MongoDB Memory Server on port 27017...');
  try {
    const mongoServer = await MongoMemoryServer.create({
      instance: { 
        port: 27017,
        dbPath: dbPath,
        storageEngine: 'wiredTiger'
      }
    });
    console.log('SUCCESS: MongoDB is running at:', mongoServer.getUri());
  } catch (err) {
    console.error('FAILED to start mongo:', err);
  }
})();
