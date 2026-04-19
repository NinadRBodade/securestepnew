const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function seed() {
  await mongoose.connect('mongodb://127.0.0.1:27017/society-safety');
  console.log('Connected to MongoDB');

  const Society = require('./src/models/Society');
  let society = await Society.findOne({ name: 'SecureStep Demo Society' });
  if (!society) {
    society = await Society.create({
      name: 'SecureStep Demo Society',
      address: '123 Demo Street, Andheri West',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400053'
    });
    console.log('Society created:', society.societyId);
  } else {
    console.log('Society exists:', society.societyId);
  }

  const User = require('./src/models/User');
  let user = await User.findOne({ email: 'resident@demo.com' });
  if (!user) {
    const hash = await bcrypt.hash('resident123', 10);
    user = await User.create({
      name: 'Demo Resident',
      email: 'resident@demo.com',
      password: hash,
      role: 'resident',
      phone: '+919876543210',
      societyId: society.societyId,
      flatNumber: 'A-101'
    });
    console.log('Resident created');
  } else { console.log('Resident exists'); }

  const Guard = require('./src/models/Guard');
  let guard = await Guard.findOne({ email: 'guard@demo.com' });
  if (!guard) {
    const gHash = await bcrypt.hash('guard123', 10);
    guard = await Guard.create({
      name: 'Demo Guard',
      email: 'guard@demo.com',
      phone: '+919876543211',
      societyId: society._id,
      password: gHash,
      tempPassword: 'guard123',
      active: true
    });
    console.log('Guard created');
  } else { console.log('Guard exists'); }

  const Agent = require('./src/models/Agent');
  let agent = await Agent.findOne({ email: 'agent@demo.com' });
  if (!agent) {
    agent = await Agent.create({
      name: 'Demo Agent',
      email: 'agent@demo.com',
      phone: '+919876543212',
      company: 'SecureStep Security Pvt Ltd',
      verified: true,
      score: 90
    });
    console.log('Agent created');
  } else { console.log('Agent exists'); }

  await mongoose.disconnect();
  console.log('');
  console.log('=== DEMO LOGIN CREDENTIALS ===');
  console.log('Society:  SecureStep Demo Society');
  console.log('Resident: resident@demo.com / resident123');
  console.log('Guard:    guard@demo.com / guard123');
  console.log('Agent:    agent@demo.com (email only)');
}

seed().catch(console.error);
