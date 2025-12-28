const nodemailer = require('nodemailer');

// Create email transporter
const createTransporter = () => {
    // Using Gmail SMTP with explicit settings for better reliability
    return nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false, // Use TLS
        auth: {
            user: process.env.EMAIL_USER || 'your-email@gmail.com',
            pass: process.env.EMAIL_PASSWORD || 'your-app-password'
        },
        tls: {
            rejectUnauthorized: false
        },
        connectionTimeout: 10000, // 10 seconds timeout
        greetingTimeout: 10000,
        socketTimeout: 10000
    });
};

/**
 * Send guard credentials via email
 * @param {Object} options - Email options
 * @param {string} options.guardEmail - Guard's email address
 * @param {string} options.guardName - Guard's name
 * @param {string} options.password - Guard's password
 * @param {string} options.societyName - Society name
 * @param {string} options.societyId - Society ID
 */
exports.sendGuardCredentials = async ({ guardEmail, guardName, password, societyName, societyId }) => {
    try {
        const transporter = createTransporter();

        const mailOptions = {
            from: process.env.EMAIL_USER || 'SecureStep <noreply@securestep.com>',
            to: guardEmail,
            subject: 'Your SecureStep Guard Login Credentials',
            html: `
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {
                            font-family: Arial, sans-serif;
                            line-height: 1.6;
                            color: #333;
                        }
                        .container {
                            max-width: 600px;
                            margin: 0 auto;
                            padding: 20px;
                            background-color: #f9f9f9;
                        }
                        .header {
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                            color: white;
                            padding: 30px;
                            text-align: center;
                            border-radius: 10px 10px 0 0;
                        }
                        .content {
                            background: white;
                            padding: 30px;
                            border-radius: 0 0 10px 10px;
                            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                        }
                        .credentials {
                            background: #f0f4ff;
                            border-left: 4px solid #667eea;
                            padding: 20px;
                            margin: 20px 0;
                        }
                        .credential-item {
                            margin: 10px 0;
                        }
                        .credential-label {
                            font-weight: bold;
                            color: #667eea;
                        }
                        .credential-value {
                            font-family: 'Courier New', monospace;
                            background: #e8f0fe;
                            padding: 8px 12px;
                            border-radius: 5px;
                            display: inline-block;
                            margin-top: 5px;
                            font-size: 16px;
                        }
                        .warning {
                            background: #fff3cd;
                            border-left: 4px solid #ffc107;
                            padding: 15px;
                            margin: 20px 0;
                        }
                        .footer {
                            text-align: center;
                            margin-top: 30px;
                            color: #666;
                            font-size: 12px;
                        }
                        .button {
                            display: inline-block;
                            background: #667eea;
                            color: white;
                            padding: 12px 30px;
                            text-decoration: none;
                            border-radius: 5px;
                            margin: 20px 0;
                        }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>🛡️ SecureStep Guard Portal</h1>
                            <p>Your Login Credentials</p>
                        </div>
                        <div class="content">
                            <h2>Hello ${guardName},</h2>
                            <p>Welcome to SecureStep! Your guard account has been created by the admin. Below are your login credentials:</p>
                            
                            <div class="credentials">
                                <div class="credential-item">
                                    <div class="credential-label">📧 Email:</div>
                                    <div class="credential-value">${guardEmail}</div>
                                </div>
                                <div class="credential-item">
                                    <div class="credential-label">🔑 Password:</div>
                                    <div class="credential-value">${password}</div>
                                </div>
                                <div class="credential-item">
                                    <div class="credential-label">🏢 Society:</div>
                                    <div class="credential-value">${societyName}</div>
                                </div>
                                <div class="credential-item">
                                    <div class="credential-label">🆔 Society ID:</div>
                                    <div class="credential-value">${societyId}</div>
                                </div>
                            </div>

                            <div class="warning">
                                <strong>⚠️ Important Security Notice:</strong>
                                <ul>
                                    <li>Keep your credentials secure and confidential</li>
                                    <li>Do not share your password with anyone</li>
                                    <li>Login only from authorized devices</li>
                                    <li>Change your password after first login (recommended)</li>
                                </ul>
                            </div>

                            <p><strong>Next Steps:</strong></p>
                            <ol>
                                <li>Open the SecureStep Guard mobile app</li>
                                <li>Use the credentials above to login</li>
                                <li>Start scanning agent QR codes for verification</li>
                            </ol>

                            <p>If you did not request this or have any questions, please contact your society administrator immediately.</p>

                            <div class="footer">
                                <p>This is an automated email from SecureStep Security System</p>
                                <p>© ${new Date().getFullYear()} SecureStep. All rights reserved.</p>
                            </div>
                        </div>
                    </div>
                </body>
                </html>
            `,
            text: `
SecureStep Guard Login Credentials

Hello ${guardName},

Your guard account has been created. Here are your login credentials:

Email: ${guardEmail}
Password: ${password}
Society: ${societyName}
Society ID: ${societyId}

IMPORTANT: Keep these credentials secure and do not share them with anyone.

Next Steps:
1. Open the SecureStep Guard mobile app
2. Use the credentials above to login
3. Start scanning agent QR codes for verification

If you have any questions, contact your society administrator.

© ${new Date().getFullYear()} SecureStep
            `
        };

        const info = await transporter.sendMail(mailOptions);
        console.log('✅ Guard credentials email sent:', info.messageId);
        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('❌ Failed to send guard credentials email:', error);
        throw error;
    }
};

// Test email configuration
exports.testEmailConfig = async () => {
    try {
        const transporter = createTransporter();
        await transporter.verify();
        console.log('✅ Email service is ready');
        return true;
    } catch (error) {
        console.error('❌ Email service configuration error:', error.message);
        return false;
    }
};
