const Agent = require('../models/Agent');
const ocrService = require('../services/ocrService');
const documentValidator = require('../services/documentValidator');
const imageForensics = require('../services/imageForensics');
const metadataAnalyzer = require('../services/metadataAnalyzer');
const VerificationResult = require('../models/VerificationResult');

exports.registerAgent = async (req, res) => {
  try {
    const { name, email, phone, agentId, company, serviceType } = req.body;
    
    if (!name || !email) {
      return res.status(400).json({ error: 'Name and email are required' });
    }

    // Get uploaded file paths
    const photo = req.files?.photo ? req.files.photo[0].path : null;
    const idProof = req.files?.idProof ? req.files.idProof[0].path : null;
    const certificate = req.files?.certificate ? req.files.certificate[0].path : null;

    // Check if agent already exists
    let agent = await Agent.findOne({ email });
    
    if (agent) {
      // Update documents and reset verification
      agent.name = name;
      agent.phone = phone || agent.phone;
      agent.company = company || agent.company;
      agent.serviceType = serviceType || agent.serviceType;
      agent.verified = false; // Reset verification on new document upload
      agent.rejected = false; // Reset rejection status
      agent.documentsUploaded = true;
      agent.uploadedAt = new Date();
      if (photo) agent.photo = photo;
      if (idProof) agent.idProof = idProof;
      if (certificate) agent.certificate = certificate;
      await agent.save();
    } else {
      // Create new agent
      agent = await Agent.create({
        id: agentId || email,
        name,
        email,
        phone: phone || 'N/A',
        company: company || 'Not Specified',
        serviceType: serviceType || 'General',
        verified: false,
        score: 0,
        documentsUploaded: true,
        uploadedAt: new Date(),
        photo,
        idProof,
        certificate
      });
    }

    // 🔥 AUTOMATIC DOCUMENT VERIFICATION
    let verificationResult = null;
    if (idProof) {
      try {
        console.log(`\n🤖 AUTO-VERIFYING DOCUMENT for ${agent.name}...`);
        
        // Run OCR + Validation + Forensics + Metadata
        const [ocrResults, validation, forensics, metadata] = await Promise.all([
          ocrService.analyzeDocument(idProof).catch(e => {
            console.error('OCR failed:', e.message);
            return { extractedFields: {}, confidence: 0, rawText: '' };
          }),
          documentValidator.validateDocument(idProof, 'ID_CARD', {}).catch(e => {
            console.error('Validation failed:', e.message);
            return { imageQuality: {}, templateValidation: {}, fieldValidation: {}, overallScore: 0 };
          }),
          imageForensics.analyzeImage(idProof).catch(e => {
            console.error('Forensics failed:', e.message);
            return { tampered: false, tamperScore: 0, indicators: [], details: {} };
          }),
          metadataAnalyzer.analyzeMetadata(idProof).catch(e => {
            console.error('Metadata failed:', e.message);
            return { metadataRisk: 'MEDIUM', hasEditingSoftware: false, isScreenshot: false, hasCameraMetadata: false, riskFactors: [] };
          })
        ]);

        // Calculate risk score
        const riskScore = calculateRiskScore({ ocrResults, validation, forensics, metadata });
        
        let riskLevel = 'LOW';
        if (riskScore >= 60) riskLevel = 'CRITICAL';
        else if (riskScore >= 40) riskLevel = 'HIGH';
        else if (riskScore >= 25) riskLevel = 'MEDIUM';

        let recommendation = 'APPROVE';
        if (riskScore >= 50 || forensics.tampered || metadata.isScreenshot || metadata.hasEditingSoftware) {
          recommendation = 'REJECT';
        } else if (riskScore >= 25) {
          recommendation = 'REVIEW';
        }

        // Save verification result
        verificationResult = await VerificationResult.create({
          agentId: agent._id,
          documentId: `AGENT_${agent.id}_${Date.now()}`,
          documentType: 'ID_CARD',
          documentPath: idProof,
          ocrResults: {
            extractedFields: ocrResults.extractedFields,
            confidence: ocrResults.confidence,
            rawText: ocrResults.rawText,
          },
          validation: {
            imageQuality: validation.imageQuality,
            templateValidation: validation.templateValidation,
            fieldValidation: validation.fieldValidation,
            overallScore: validation.overallScore,
          },
          forensics: {
            tampered: forensics.tampered,
            tamperScore: forensics.tamperScore,
            indicators: forensics.indicators,
            details: forensics.details,
          },
          metadata: {
            risk: metadata.metadataRisk,
            hasEditingSoftware: metadata.hasEditingSoftware,
            isScreenshot: metadata.isScreenshot,
            hasCameraMetadata: metadata.hasCameraMetadata,
            riskFactors: metadata.riskFactors,
          },
          riskScore,
          riskLevel,
          recommendation,
          verifiedAt: new Date(),
        });

        console.log(`✅ AUTO-VERIFICATION COMPLETE: ${riskLevel} (${riskScore}/100) - ${recommendation}`);
      } catch (verifyError) {
        console.error('⚠️ Auto-verification failed:', verifyError.message);
      }
    }

    res.json({
      success: true,
      message: 'Documents submitted and automatically verified. Admin will review.',
      agent: {
        id: agent.id,
        name: agent.name,
        email: agent.email,
        verified: agent.verified
      },
      verification: verificationResult ? {
        riskScore: verificationResult.riskScore,
        riskLevel: verificationResult.riskLevel,
        recommendation: verificationResult.recommendation
      } : null
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Risk calculation helper
function calculateRiskScore({ ocrResults, validation, forensics, metadata }) {
  let score = 0;
  const ocrConfidence = ocrResults.confidence || 0;
  const fields = ocrResults.extractedFields || {};
  
  if (ocrConfidence < 0.5) score += 40;
  else if (ocrConfidence < 0.7) score += 25;
  else if (ocrConfidence < 0.85) score += 10;
  
  if (!fields.name || fields.name.length < 3) score += 30;
  if (!fields.idNumber || fields.idNumber.length < 5) score += 30;
  if (!fields.dateOfBirth) score += 20;
  
  const validationScore = validation.overallScore || 0;
  if (validationScore < 0.4) score += 35;
  else if (validationScore < 0.6) score += 20;
  else if (validationScore < 0.8) score += 10;
  
  if (!validation.imageQuality?.isGood) score += 25;
  if (!validation.templateValidation?.isValid) score += 30;
  
  if (forensics.tampered) score += 50;
  const tamperScore = (forensics.tamperScore || 0) * 100;
  if (tamperScore > 60) score += 40;
  else if (tamperScore > 40) score += 20;
  
  if (metadata.hasEditingSoftware) score += 35;
  if (metadata.isScreenshot) score += 45;
  if (!metadata.hasCameraMetadata) score += 15;
  
  return Math.min(100, Math.round(score));
}

exports.getProfile = async (req, res) => {
  try {
    const { email } = req.params;
    
    const agent = await Agent.findOne({ email });
    
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found. Please upload documents first.' });
    }

    res.json({
      success: true,
      agent: {
        id: agent.id,
        name: agent.name,
        email: agent.email,
        company: agent.company,
        verified: agent.verified,
        score: agent.score || 0,
        documentsUploaded: agent.documentsUploaded || false
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.verifyQR = async (req, res) => {
  try {
    console.log('📱 POST /api/agents/verify-qr called');
    console.log('📦 Request body:', JSON.stringify(req.body));
    
    // Extract QR data from request body
    const qrData = req.body;
    
    if (!qrData || !qrData.id || !qrData.email) {
      console.log('❌ Missing required fields in QR data');
      return res.status(400).json({ 
        success: false,
        error: 'Invalid QR code: missing required fields (id, email)' 
      });
    }

    // Find agent by ID or email
    const agent = await Agent.findOne({ 
      $or: [
        { id: qrData.id },
        { email: qrData.email }
      ]
    });
    
    if (!agent) {
      console.log(`❌ Agent not found: ${qrData.email}`);
      return res.status(404).json({ 
        success: false,
        error: 'Agent not found in database' 
      });
    }

    console.log(`✅ Agent verified: ${agent.name} (${agent.email})`);

    // Return agent details as JSON ONLY (no HTML, no redirects)
    return res.status(200).json({
      success: true,
      agent: {
        id: agent.id,
        name: agent.name,
        email: agent.email,
        phone: agent.phone,
        company: agent.company,
        verified: agent.verified,
        score: agent.score || 0,
        documentsUploaded: agent.documentsUploaded || false,
        serviceType: agent.serviceType || 'General'
      }
    });
  } catch (error) {
    console.error('❌ Error in verifyQR:', error);
    return res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
};

exports.updateProfile = async (req, res) => {
  res.json({ status: 'success', message: 'Update profile - Coming soon' });
};

exports.getSafetyScore = async (req, res) => {
  res.json({ status: 'success', data: { score: 100 } });
};
