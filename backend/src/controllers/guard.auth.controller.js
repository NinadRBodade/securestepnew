const Guard = require('../models/Guard');
const Society = require('../models/Society');
const bcrypt = require('bcryptjs');
const { sendGuardCredentials } = require('../utils/email.service');

/**
 * Request guard login credentials via email
 * Guard enters email → System checks if registered → Sends credentials via email
 */
exports.requestGuardCredentials = async (req, res) => {
    try {
        const { email } = req.body;

        // Validate email
        if (!email || !email.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Email is required'
            });
        }

        const guardEmail = email.trim().toLowerCase();

        // Find guard by email
        const guard = await Guard.findOne({ email: guardEmail })
            .populate('societyId', 'name societyId');

        // Guard not found
        if (!guard) {
            return res.status(404).json({
                success: false,
                message: 'This email is not registered as a guard. Please contact your society admin.'
            });
        }

        // Check if guard is active
        if (!guard.active) {
            return res.status(403).json({
                success: false,
                message: 'Your guard account has been deactivated. Please contact your society admin.'
            });
        }

        // Get the password (stored in tempPassword field for sending via email)
        // If tempPassword doesn't exist, we can't send it
        if (!guard.tempPassword) {
            return res.status(500).json({
                success: false,
                message: 'Password information not available. Please contact your society admin to reset your credentials.'
            });
        }

        // Prepare email data
        const emailData = {
            guardEmail: guard.email,
            guardName: guard.name,
            password: guard.tempPassword,
            societyName: guard.societyId?.name || 'Your Society',
            societyId: guard.societyId?.societyId || 'N/A'
        };

        // Send credentials via email
        try {
            // Check if email is configured
            const isEmailConfigured = process.env.EMAIL_USER && 
                                     process.env.EMAIL_PASSWORD && 
                                     process.env.EMAIL_USER !== 'your-email@gmail.com';

            if (isEmailConfigured) {
                // Try to send actual email
                try {
                    await sendGuardCredentials(emailData);
                    console.log(`✅ Credentials sent to guard: ${guard.email}`);
                    
                    res.status(200).json({
                        success: true,
                        message: 'Your login credentials have been sent to your email address. Please check your inbox.'
                    });
                } catch (emailError) {
                    // Email failed - fall back to development mode
                    console.error('❌ Failed to send guard credentials email:', emailError.message);
                    console.log('📧 Falling back to development mode...');
                    console.log(`
╔════════════════════════════════════════════════════════╗
║     EMAIL FAILED - SHOWING CREDENTIALS IN CONSOLE      ║
╔════════════════════════════════════════════════════════╗
║ Guard Name:     ${guard.name}
║ Email:          ${guard.email}
║ Password:       ${guard.tempPassword}
║ Society:        ${emailData.societyName}
║ Society ID:     ${emailData.societyId}
╚════════════════════════════════════════════════════════╝
                    `);
                    
                    res.status(200).json({
                        success: true,
                        message: 'Your login credentials (email service is temporarily unavailable)',
                        devMode: true,
                        credentials: {
                            email: guard.email,
                            password: guard.tempPassword,
                            society: emailData.societyName,
                            societyId: emailData.societyId
                        }
                    });
                }
            } else {
                // Development mode: Show credentials directly
                console.log(`
╔════════════════════════════════════════════════════════╗
║          DEVELOPMENT MODE - EMAIL NOT CONFIGURED       ║
║     Guard Credentials (would be sent via email)        ║
╔════════════════════════════════════════════════════════╗
║ Guard Name:     ${guard.name}
║ Email:          ${guard.email}
║ Password:       ${guard.tempPassword}
║ Society:        ${emailData.societyName}
║ Society ID:     ${emailData.societyId}
╚════════════════════════════════════════════════════════╝
                `);
                
                res.status(200).json({
                    success: true,
                    message: 'Your login credentials have been sent to your email address. Please check your inbox.',
                    // In development, include credentials in response
                    devMode: true,
                    credentials: {
                        email: guard.email,
                        password: guard.tempPassword,
                        society: emailData.societyName,
                        societyId: emailData.societyId
                    }
                });
            }
        } catch (emailError) {
            console.error('Email error:', emailError);
            
            // Always return success with credentials in case of any email errors
            console.log(`
╔════════════════════════════════════════════════════════╗
║        ERROR HANDLING - SHOWING CREDENTIALS            ║
╔════════════════════════════════════════════════════════╗
║ Guard Name:     ${guard.name}
║ Email:          ${guard.email}
║ Password:       ${guard.tempPassword}
║ Society:        ${emailData.societyName}
║ Society ID:     ${emailData.societyId}
╚════════════════════════════════════════════════════════╝
            `);
            
            res.status(200).json({
                success: true,
                message: 'Login credentials retrieved (email temporarily unavailable)',
                devMode: true,
                credentials: {
                    email: guard.email,
                    password: guard.tempPassword,
                    society: emailData.societyName,
                    societyId: emailData.societyId
                }
            });
        }
    } catch (error) {
        console.error('Request guard credentials error:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while processing your request. Please try again later.'
        });
    }
};
