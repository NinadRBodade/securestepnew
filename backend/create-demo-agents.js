const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '.env') });

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/society_safety', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

const Agent = require('./src/models/Agent');

async function createDemoAgents() {
  try {
    console.log('🔄 Creating demo agents...');

    // Clear existing demo agents
    await Agent.deleteMany({ email: { $regex: '@demo.com' } });

    const demoAgents = [
      {
        id: 'agent001',
        name: 'John Delivery',
        email: 'john.delivery@demo.com',
        phone: '+1234567890',
        company: 'Amazon Logistics',
        serviceType: 'Delivery',
        verified: false,
        documentsUploaded: true,
        uploadedAt: new Date(),
        photo: '/uploads/agents/demo-agent-1.jpg',
        idProof: '/uploads/agents/demo-id-1.jpg',
        certificate: '/uploads/agents/demo-cert-1.jpg'
      },
      {
        id: 'agent002',
        name: 'Sarah Plumber',
        email: 'sarah.plumber@demo.com',
        phone: '+1234567891',
        company: 'QuickFix Services',
        serviceType: 'Plumbing',
        verified: true,
        score: 85,
        documentsUploaded: true,
        uploadedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        photo: '/uploads/agents/demo-agent-2.jpg',
        idProof: '/uploads/agents/demo-id-2.jpg',
        certificate: '/uploads/agents/demo-cert-2.jpg',
        qrData: JSON.stringify({
          id: 'agent002',
          name: 'Sarah Plumber',
          email: 'sarah.plumber@demo.com',
          company: 'QuickFix Services',
          verified: true,
          score: 85
        })
      },
      {
        id: 'agent003',
        name: 'Mike Electrician',
        email: 'mike.electric@demo.com',
        phone: '+1234567892',
        company: 'BrightSpark Electric',
        serviceType: 'Electrical',
        verified: true,
        score: 92,
        documentsUploaded: true,
        uploadedAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
        photo: '/uploads/agents/demo-agent-3.jpg',
        idProof: '/uploads/agents/demo-id-3.jpg',
        certificate: '/uploads/agents/demo-cert-3.jpg',
        qrData: JSON.stringify({
          id: 'agent003',
          name: 'Mike Electrician',
          email: 'mike.electric@demo.com',
          company: 'BrightSpark Electric',
          verified: true,
          score: 92
        })
      },
      {
        id: 'agent004',
        name: 'Lisa Courier',
        email: 'lisa.courier@demo.com',
        phone: '+1234567893',
        company: 'DHL Express',
        serviceType: 'Courier',
        verified: false,
        documentsUploaded: true,
        uploadedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
        photo: '/uploads/agents/demo-agent-4.jpg',
        idProof: '/uploads/agents/demo-id-4.jpg',
        certificate: '/uploads/agents/demo-cert-4.jpg'
      },
      {
        id: 'agent005',
        name: 'Tom Painter',
        email: 'tom.painter@demo.com',
        phone: '+1234567894',
        company: 'ColorWorld Painting',
        serviceType: 'Painting',
        verified: false,
        rejected: true,
        rejectionReason: 'Incomplete documentation',
        rejectedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        documentsUploaded: true,
        uploadedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        photo: '/uploads/agents/demo-agent-5.jpg',
        idProof: '/uploads/agents/demo-id-5.jpg'
      },
      {
        id: 'agent006',
        name: 'Emma Cleaner',
        email: 'emma.cleaner@demo.com',
        phone: '+1234567895',
        company: 'SparkleClean Services',
        serviceType: 'Cleaning',
        verified: true,
        score: 78,
        documentsUploaded: true,
        uploadedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
        photo: '/uploads/agents/demo-agent-6.jpg',
        idProof: '/uploads/agents/demo-id-6.jpg',
        certificate: '/uploads/agents/demo-cert-6.jpg',
        qrData: JSON.stringify({
          id: 'agent006',
          name: 'Emma Cleaner',
          email: 'emma.cleaner@demo.com',
          company: 'SparkleClean Services',
          verified: true,
          score: 78
        })
      },
      {
        id: 'agent007',
        name: 'David Carpenter',
        email: 'david.carpenter@demo.com',
        phone: '+1234567896',
        company: 'WoodWorks Pro',
        serviceType: 'Carpentry',
        verified: false,
        documentsUploaded: true,
        uploadedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        photo: '/uploads/agents/demo-agent-7.jpg',
        idProof: '/uploads/agents/demo-id-7.jpg',
        certificate: '/uploads/agents/demo-cert-7.jpg'
      }
    ];

    await Agent.insertMany(demoAgents);

    console.log('✅ Demo agents created successfully!');
    console.log(`
╔════════════════════════════════════════════════════════╗
║  📊 Demo Agents Summary                                ║
╠════════════════════════════════════════════════════════╣
║  Total:    ${demoAgents.length} agents                             ║
║  Pending:  ${demoAgents.filter(a => !a.verified && !a.rejected).length} agents                             ║
║  Verified: ${demoAgents.filter(a => a.verified).length} agents                             ║
║  Rejected: ${demoAgents.filter(a => a.rejected).length} agent                              ║
╚════════════════════════════════════════════════════════╝

Demo Agent Credentials:
- john.delivery@demo.com (Pending)
- sarah.plumber@demo.com (Verified - Score: 85)
- mike.electric@demo.com (Verified - Score: 92)
- lisa.courier@demo.com (Pending)
- tom.painter@demo.com (Rejected)
- emma.cleaner@demo.com (Verified - Score: 78)
- david.carpenter@demo.com (Pending)
    `);

    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating demo agents:', error);
    process.exit(1);
  }
}

mongoose.connection.once('open', () => {
  console.log('✅ Connected to MongoDB');
  createDemoAgents();
});
