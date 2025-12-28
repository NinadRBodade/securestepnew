// Script to create demo societies and guards for testing

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/society-safety';

// Models
const Society = require('./src/models/Society');
const Guard = require('./src/models/Guard');

// Demo societies data
const demoSocieties = [
    {
        name: 'Green Valley Apartments',
        address: '123 Green Valley Road',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001'
    },
    {
        name: 'Sunshine Residency',
        address: '456 Sunshine Boulevard',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001'
    },
    {
        name: 'Royal Gardens',
        address: '789 Royal Gardens Street',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001'
    },
    {
        name: 'Paradise Heights',
        address: '321 Paradise Lane',
        city: 'Chennai',
        state: 'Tamil Nadu',
        pincode: '600001'
    },
    {
        name: 'Lake View Towers',
        address: '654 Lake View Drive',
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500001'
    }
];

// Demo guards data (will be linked to societies)
const demoGuards = [
    { name: 'Ramesh Kumar', email: 'ramesh.guard@greenvalley.com', phone: '9876543210' },
    { name: 'Suresh Patil', email: 'suresh.guard@greenvalley.com', phone: '9876543211' },
    { name: 'Amit Singh', email: 'amit.guard@sunshine.com', phone: '9876543212' },
    { name: 'Vijay Sharma', email: 'vijay.guard@sunshine.com', phone: '9876543213' },
    { name: 'Rajesh Verma', email: 'rajesh.guard@royal.com', phone: '9876543214' },
    { name: 'Prakash Reddy', email: 'prakash.guard@paradise.com', phone: '9876543215' },
    { name: 'Anil Nair', email: 'anil.guard@lakeview.com', phone: '9876543216' }
];

// Generate random password
function generatePassword() {
    return Math.random().toString(36).slice(-8);
}

async function createDemoData() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        // Clear existing demo data
        console.log('🗑️  Clearing existing demo data...');
        await Society.deleteMany({ name: { $in: demoSocieties.map(s => s.name) } });
        await Guard.deleteMany({ email: { $regex: /@(greenvalley|sunshine|royal|paradise|lakeview)\.com$/ } });
        console.log('✅ Cleared old demo data\n');

        // Create societies
        console.log('🏘️  Creating demo societies...');
        const createdSocieties = [];
        for (const societyData of demoSocieties) {
            const society = await Society.create(societyData);
            createdSocieties.push(society);
            console.log(`   ✅ Created: ${society.name} (ID: ${society.societyId})`);
        }
        console.log(`\n✅ Created ${createdSocieties.length} societies\n`);

        // Create guards
        console.log('👮 Creating demo guards...');
        const guardMapping = [
            { societyIndex: 0, guardIndexes: [0, 1] }, // Green Valley - 2 guards
            { societyIndex: 1, guardIndexes: [2, 3] }, // Sunshine - 2 guards
            { societyIndex: 2, guardIndexes: [4] },    // Royal - 1 guard
            { societyIndex: 3, guardIndexes: [5] },    // Paradise - 1 guard
            { societyIndex: 4, guardIndexes: [6] }     // Lake View - 1 guard
        ];

        let guardCount = 0;
        for (const mapping of guardMapping) {
            const society = createdSocieties[mapping.societyIndex];
            
            for (const guardIndex of mapping.guardIndexes) {
                const guardData = demoGuards[guardIndex];
                const tempPassword = generatePassword();
                const hashedPassword = await bcrypt.hash(tempPassword, 10);
                
                const guard = await Guard.create({
                    name: guardData.name,
                    email: guardData.email,
                    phone: guardData.phone,
                    societyId: society._id,
                    password: hashedPassword,
                    tempPassword,
                    active: true
                });
                
                guardCount++;
                console.log(`   ✅ Created: ${guard.name} → ${society.name}`);
                console.log(`      Email: ${guard.email} | Password: ${tempPassword}`);
                
                // Update society guard count
                society.guardCount = (society.guardCount || 0) + 1;
                await society.save();
            }
        }
        console.log(`\n✅ Created ${guardCount} guards\n`);

        // Summary
        console.log('📊 DEMO DATA SUMMARY');
        console.log('='.repeat(60));
        console.log(`Total Societies: ${createdSocieties.length}`);
        console.log(`Total Guards: ${guardCount}`);
        console.log('\n🏘️  SOCIETIES:');
        for (const society of createdSocieties) {
            const guards = await Guard.countDocuments({ societyId: society._id });
            console.log(`   • ${society.name} (${society.societyId}) - ${guards} guard(s)`);
            console.log(`     📍 ${society.city}, ${society.state}`);
        }
        
        console.log('\n👮 GUARDS & CREDENTIALS:');
        const allGuards = await Guard.find().populate('societyId', 'name');
        for (const guard of allGuards) {
            console.log(`   • ${guard.name}`);
            console.log(`     Society: ${guard.societyId.name}`);
            console.log(`     Email: ${guard.email}`);
            console.log(`     Password: ${guard.tempPassword}`);
            console.log('');
        }

        console.log('='.repeat(60));
        console.log('\n✅ Demo data created successfully!');
        console.log('\n🌐 Access Admin Dashboard:');
        console.log('   http://localhost:8080/admin_portal/index.html');
        console.log('\n📝 Note: Guard credentials are shown above. In production,');
        console.log('   these would be sent via email.\n');

    } catch (error) {
        console.error('❌ Error creating demo data:', error);
        process.exit(1);
    } finally {
        await mongoose.disconnect();
        console.log('👋 Disconnected from MongoDB');
        process.exit(0);
    }
}

// Run the script
createDemoData();
