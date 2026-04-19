const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function seedGuards() {
  await mongoose.connect('mongodb://127.0.0.1:27017/society-safety');
  console.log('Connected to MongoDB');

  const Guard = require('./src/models/Guard');
  const Society = require('./src/models/Society');

  const society = await Society.findOne({ name: 'SecureStep Demo Society' });
  if (!society) {
    console.log('❌ Society not found! Run node seed-demo.js first.');
    return mongoose.disconnect();
  }
  console.log('✅ Society:', society.name, '| _id:', society._id);

  const hash = await bcrypt.hash('guard123', 10);

  const guards = [
    { name: 'Mahesh Bhosale', email: 'mahesh.g@securestep.com',  phone: '+919800000101', societyId: society._id, password: hash, tempPassword: 'guard123', active: true },
    { name: 'Santosh Wagh',   email: 'santosh.g@securestep.com', phone: '+919800000102', societyId: society._id, password: hash, tempPassword: 'guard123', active: true },
    { name: 'Deepak Kamble',  email: 'deepak.g@securestep.com',  phone: '+919800000103', societyId: society._id, password: hash, tempPassword: 'guard123', active: true },
    { name: 'Ramesh Mane',    email: 'ramesh.g@securestep.com',  phone: '+919800000104', societyId: society._id, password: hash, tempPassword: 'guard123', active: true },
    { name: 'Ganesh Jadhav',  email: 'ganesh.g@securestep.com',  phone: '+919800000105', societyId: society._id, password: hash, tempPassword: 'guard123', active: true },
    { name: 'Sunil Pawar',    email: 'sunil.g@securestep.com',   phone: '+919800000106', societyId: society._id, password: hash, tempPassword: 'guard123', active: false },
    { name: 'Vijay Kale',     email: 'vijay.g@securestep.com',   phone: '+919800000107', societyId: society._id, password: hash, tempPassword: 'guard123', active: true },
    { name: 'Prakash Shinde', email: 'prakash.g@securestep.com', phone: '+919800000108', societyId: society._id, password: hash, tempPassword: 'guard123', active: true }
  ];

  let added = 0;
  for (const g of guards) {
    const exists = await Guard.findOne({ email: g.email });
    if (!exists) {
      await Guard.create(g);
      console.log('✅ Added:', g.name, '|', g.email, '|', g.active ? '🟢 Active' : '🔴 Inactive');
      added++;
    } else {
      console.log('⏭️  Skipped (exists):', g.name);
    }
  }

  const total = await Guard.countDocuments();
  console.log('\n✅ Done! Added', added, 'new guards');
  console.log('📊 Total guards in DB:', total);
  console.log('🔑 All login with password: guard123');
  mongoose.disconnect();
}

seedGuards().catch(console.error);
