require('dotenv').config();
const nodemailer = require('nodemailer');

console.log('📧 Testing Email Configuration...\n');
console.log('Email User:', process.env.EMAIL_USER);
console.log('Email Password:', process.env.EMAIL_PASSWORD ? '***' + process.env.EMAIL_PASSWORD.slice(-4) : 'NOT SET');
console.log('\n');

// Create transporter
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false, // Use TLS
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    },
    tls: {
        rejectUnauthorized: false
    },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 10000
});

// Verify connection
console.log('🔍 Verifying SMTP connection...');
transporter.verify((error, success) => {
    if (error) {
        console.log('\n❌ Email Configuration ERROR:');
        console.log(error.message);
        console.log('\n📝 To fix this:');
        console.log('1. Go to https://myaccount.google.com/security');
        console.log('2. Enable "2-Step Verification" if not already enabled');
        console.log('3. Go to https://myaccount.google.com/apppasswords');
        console.log('4. Create a new "App Password" for "Mail"');
        console.log('5. Update EMAIL_PASSWORD in backend/.env with the 16-character password');
        console.log('\n');
    } else {
        console.log('✅ Email Configuration is WORKING!');
        console.log('Server is ready to send emails.\n');
        
        // Send test email
        console.log('📨 Sending test email...');
        transporter.sendMail({
            from: process.env.EMAIL_USER,
            to: process.env.EMAIL_USER, // Send to yourself
            subject: 'SecureStep Email Test',
            html: '<h2>✅ Success!</h2><p>Your email configuration is working correctly.</p>'
        }, (err, info) => {
            if (err) {
                console.log('❌ Failed to send test email:', err.message);
            } else {
                console.log('✅ Test email sent successfully!');
                console.log('Message ID:', info.messageId);
            }
            process.exit(0);
        });
    }
});
