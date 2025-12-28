const ocrService = require('../services/ocrService');
const documentValidator = require('../services/documentValidator');
const imageForensics = require('../services/imageForensics');
const metadataAnalyzer = require('../services/metadataAnalyzer');
const VerificationResult = require('../models/VerificationResult');
const path = require('path');
const fs = require('fs').promises;

/**
 * Verify a document using OCR and forensics
 */
exports.verifyDocument = async (req, res) => {
  try {
    const { documentId, agentId, documentType } = req.body;
    const documentPath = req.file?.path;

    if (!documentPath) {
      return res.status(400).json({
        success: false,
        message: 'No document image provided',
      });
    }

    if (!documentId || !agentId) {
      return res.status(400).json({
        success: false,
        message: 'Document ID and Agent ID are required',
      });
    }

    console.log(`\n🔍 Starting document verification for ${documentId}...`);
    console.log(`📄 Document Type: ${documentType || 'Unknown'}`);
    console.log(`👤 Agent ID: ${agentId}`);
    console.log(`📁 File: ${documentPath}`);

    // Step 1: OCR Analysis
    console.log('\n📝 Step 1: OCR Analysis...');
    const ocrResults = await ocrService.analyzeDocument(documentPath);
    
    if (!ocrResults.success) {
      return res.status(500).json({
        success: false,
        message: 'OCR analysis failed',
        error: ocrResults.error,
      });
    }

    // Step 2: Document Validation
    console.log('\n✅ Step 2: Document Validation...');
    const validation = await documentValidator.validateDocument(
      documentPath,
      documentType || 'ID_CARD',
      ocrResults.extractedFields
    );

    // Step 3: Forensics Analysis
    console.log('\n🔬 Step 3: Forensics Analysis...');
    const forensics = await imageForensics.analyzeImage(documentPath);

    // Step 4: Metadata Analysis
    console.log('\n📊 Step 4: Metadata Analysis...');
    const metadata = await metadataAnalyzer.analyzeMetadata(documentPath);

    // Step 5: Calculate Risk Score
    console.log('\n⚠️ Step 5: Calculating Risk Score...');
    const riskScore = calculateRiskScore({
      ocrResults,
      validation,
      forensics,
      metadata,
    });

    // Determine risk level - STRICTER THRESHOLDS
    let riskLevel = 'LOW';
    if (riskScore >= 60) riskLevel = 'CRITICAL';
    else if (riskScore >= 40) riskLevel = 'HIGH';
    else if (riskScore >= 25) riskLevel = 'MEDIUM';

    // Determine recommendation - STRICTER
    let recommendation = 'APPROVE';
    if (riskScore >= 50) {
      recommendation = 'REJECT';
    } else if (riskScore >= 25) {
      recommendation = 'REVIEW';
    }

    // Force REJECT if critical issues detected
    if (forensics.tampered || metadata.isScreenshot || metadata.hasEditingSoftware) {
      recommendation = 'REJECT';
      if (riskLevel === 'LOW' || riskLevel === 'MEDIUM') {
        riskLevel = 'HIGH';
      }
    }

    // Step 6: Save to Database
    console.log('\n💾 Step 6: Saving to Database...');
    const verificationResult = new VerificationResult({
      agentId,
      documentId,
      documentType: documentType || 'ID_CARD',
      documentPath: documentPath.replace(/\\/g, '/'),
      
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

    await verificationResult.save();

    console.log(`\n✅ Verification Complete!`);
    console.log(`📊 Risk Score: ${riskScore}/100`);
    console.log(`⚠️ Risk Level: ${riskLevel}`);
    console.log(`💡 Recommendation: ${recommendation}`);

    res.json({
      success: true,
      message: 'Document verification completed',
      verificationId: verificationResult._id,
      results: {
        riskScore,
        riskLevel,
        recommendation,
        ocrFields: ocrResults.extractedFields,
        validationScore: validation.overallScore,
        tampered: forensics.tampered,
        tamperScore: forensics.tamperScore,
        metadataRisk: metadata.metadataRisk,
      },
    });

  } catch (error) {
    console.error('❌ Document verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Document verification failed',
      error: error.message,
    });
  }
};

/**
 * Get verification result by ID
 */
exports.getVerificationResult = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await VerificationResult.findById(id)
      .populate('agentId', 'name email phone')
      .populate('adminDecision.decidedBy', 'name email');

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Verification result not found',
      });
    }

    res.json({
      success: true,
      result,
    });

  } catch (error) {
    console.error('Error fetching verification result:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch verification result',
      error: error.message,
    });
  }
};

/**
 * Get all pending verifications
 */
exports.getPendingVerifications = async (req, res) => {
  try {
    const results = await VerificationResult.find({
      'adminDecision.status': 'PENDING',
    })
      .populate('agentId', 'name email phone')
      .sort({ verifiedAt: -1 });

    res.json({
      success: true,
      count: results.length,
      results,
    });

  } catch (error) {
    console.error('Error fetching pending verifications:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch pending verifications',
      error: error.message,
    });
  }
};

/**
 * Approve a verification
 */
exports.approveVerification = async (req, res) => {
  try {
    const { id } = req.params;
    const { adminId, notes } = req.body;

    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: 'Admin ID is required',
      });
    }

    const result = await VerificationResult.findById(id);
    
    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Verification result not found',
      });
    }

    await result.approve(adminId, notes);

    res.json({
      success: true,
      message: 'Verification approved',
      result,
    });

  } catch (error) {
    console.error('Error approving verification:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve verification',
      error: error.message,
    });
  }
};

/**
 * Reject a verification
 */
exports.rejectVerification = async (req, res) => {
  try {
    const { id } = req.params;
    const { adminId, reason } = req.body;

    if (!adminId || !reason) {
      return res.status(400).json({
        success: false,
        message: 'Admin ID and rejection reason are required',
      });
    }

    const result = await VerificationResult.findById(id);
    
    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Verification result not found',
      });
    }

    await result.reject(adminId, reason);

    res.json({
      success: true,
      message: 'Verification rejected',
      result,
    });

  } catch (error) {
    console.error('Error rejecting verification:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject verification',
      error: error.message,
    });
  }
};

/**
 * Get verification stats
 */
exports.getVerificationStats = async (req, res) => {
  try {
    const total = await VerificationResult.countDocuments();
    const pending = await VerificationResult.countDocuments({ 'adminDecision.status': 'PENDING' });
    const approved = await VerificationResult.countDocuments({ 'adminDecision.status': 'APPROVED' });
    const rejected = await VerificationResult.countDocuments({ 'adminDecision.status': 'REJECTED' });

    const criticalRisk = await VerificationResult.countDocuments({ riskLevel: 'CRITICAL' });
    const highRisk = await VerificationResult.countDocuments({ riskLevel: 'HIGH' });

    res.json({
      success: true,
      stats: {
        total,
        pending,
        approved,
        rejected,
        criticalRisk,
        highRisk,
      },
    });

  } catch (error) {
    console.error('Error fetching verification stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch verification stats',
      error: error.message,
    });
  }
};

/**
 * Calculate overall risk score - STRICT VALIDATION
 */
function calculateRiskScore({ ocrResults, validation, forensics, metadata }) {
  let score = 0;
  const penalties = [];

  // OCR confidence check - STRICT
  const ocrConfidence = ocrResults.confidence || 0;
  if (ocrConfidence < 0.5) {
    score += 40;
    penalties.push('Very low OCR confidence');
  } else if (ocrConfidence < 0.7) {
    score += 25;
    penalties.push('Low OCR confidence');
  } else if (ocrConfidence < 0.85) {
    score += 10;
  }

  // Check if critical fields are missing
  const fields = ocrResults.extractedFields || {};
  if (!fields.name || fields.name.length < 3) {
    score += 30;
    penalties.push('Name not found or invalid');
  }
  if (!fields.idNumber || fields.idNumber.length < 5) {
    score += 30;
    penalties.push('ID number not found');
  }
  if (!fields.dateOfBirth) {
    score += 20;
    penalties.push('Date of birth missing');
  }

  // Validation score - STRICT
  const validationScore = validation.overallScore || 0;
  if (validationScore < 0.4) {
    score += 35;
    penalties.push('Poor document validation');
  } else if (validationScore < 0.6) {
    score += 20;
    penalties.push('Low validation score');
  } else if (validationScore < 0.8) {
    score += 10;
  }

  // Image quality check
  if (!validation.imageQuality?.isGood) {
    score += 25;
    penalties.push('Poor image quality');
  }

  // Template validation
  if (!validation.templateValidation?.isValid) {
    score += 30;
    penalties.push('Document template invalid');
  }

  // Forensics - CRITICAL
  if (forensics.tampered) {
    score += 50;
    penalties.push('⚠️ TAMPERING DETECTED');
  }
  const tamperScore = (forensics.tamperScore || 0) * 100;
  if (tamperScore > 60) {
    score += 40;
    penalties.push('High tampering score');
  } else if (tamperScore > 40) {
    score += 20;
  }

  // Metadata risk - STRICT
  if (metadata.hasEditingSoftware) {
    score += 35;
    penalties.push('Editing software detected');
  }
  if (metadata.isScreenshot) {
    score += 45;
    penalties.push('⚠️ Screenshot detected');
  }
  if (!metadata.hasCameraMetadata) {
    score += 15;
    penalties.push('Missing camera metadata');
  }

  const finalScore = Math.min(100, Math.round(score));
  
  console.log(`\n📊 Risk Calculation:`);
  console.log(`   OCR Confidence: ${(ocrConfidence * 100).toFixed(1)}%`);
  console.log(`   Validation Score: ${(validationScore * 100).toFixed(1)}%`);
  console.log(`   Tampered: ${forensics.tampered ? 'YES ⚠️' : 'No'}`);
  console.log(`   Penalties: ${penalties.join(', ') || 'None'}`);
  console.log(`   Final Risk Score: ${finalScore}/100`);

  return finalScore;
}

module.exports = exports;
