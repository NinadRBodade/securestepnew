const sharp = require('sharp');

class DocumentValidator {
  /**
   * Validate ID number format based on document type
   */
  validateIDNumber(idNumber, documentType = 'ID_CARD') {
    const patterns = {
      ID_CARD: /^[A-Z]{2}[0-9]{6,12}$/i, // Example: AB123456789
      PASSPORT: /^[A-Z][0-9]{7,9}$/i, // Example: A1234567
      DRIVING_LICENSE: /^[A-Z0-9]{8,15}$/i,
      AADHAR: /^[0-9]{12}$/, // India Aadhar
      PAN: /^[A-Z]{5}[0-9]{4}[A-Z]$/i, // India PAN
    };

    const pattern = patterns[documentType] || patterns.ID_CARD;
    return pattern.test(idNumber);
  }

  /**
   * Validate date format and sanity
   */
  validateDate(dateStr) {
    try {
      const date = new Date(dateStr);
      const now = new Date();
      
      // Check if valid date
      if (isNaN(date.getTime())) {
        return { valid: false, reason: 'Invalid date format' };
      }
      
      // Check if not in future
      if (date > now) {
        return { valid: false, reason: 'Date cannot be in future' };
      }
      
      // Check if not too old (e.g., 150 years)
      const minDate = new Date();
      minDate.setFullYear(minDate.getFullYear() - 150);
      if (date < minDate) {
        return { valid: false, reason: 'Date too old' };
      }
      
      return { valid: true };
    } catch (error) {
      return { valid: false, reason: 'Date parsing error' };
    }
  }

  /**
   * Validate expiry date
   */
  validateExpiryDate(expiryStr) {
    try {
      const expiry = new Date(expiryStr);
      const now = new Date();
      
      if (isNaN(expiry.getTime())) {
        return { valid: false, expired: true, reason: 'Invalid expiry date' };
      }
      
      const expired = expiry < now;
      
      return {
        valid: true,
        expired,
        daysRemaining: Math.ceil((expiry - now) / (1000 * 60 * 60 * 24)),
      };
    } catch (error) {
      return { valid: false, expired: true, reason: 'Expiry parsing error' };
    }
  }

  /**
   * Validate document age consistency
   */
  validateAgeConsistency(dob, issueDate) {
    try {
      const birthDate = new Date(dob);
      const documentDate = new Date(issueDate || Date.now());
      
      const ageAtIssue = (documentDate - birthDate) / (1000 * 60 * 60 * 24 * 365.25);
      
      // Most documents require minimum age of 18
      if (ageAtIssue < 18) {
        return { valid: false, reason: 'Age below minimum requirement' };
      }
      
      // Maximum age check (150 years)
      if (ageAtIssue > 150) {
        return { valid: false, reason: 'Age exceeds maximum' };
      }
      
      return { valid: true, age: Math.floor(ageAtIssue) };
    } catch (error) {
      return { valid: false, reason: 'Age calculation error' };
    }
  }

  /**
   * Analyze image dimensions and quality
   */
  async analyzeImageQuality(imagePath) {
    try {
      const metadata = await sharp(imagePath).metadata();
      const stats = await sharp(imagePath).stats();
      
      const { width, height, format, space, density, hasAlpha } = metadata;
      
      // Resolution check (minimum 600x400)
      const resolutionValid = width >= 600 && height >= 400;
      
      // Aspect ratio check (typical ID cards: 1.5-1.8)
      const aspectRatio = width / height;
      const aspectRatioValid = aspectRatio >= 1.4 && aspectRatio <= 2.0;
      
      // Check if image is too bright or too dark
      const avgBrightness = stats.channels.reduce((sum, ch) => sum + ch.mean, 0) / stats.channels.length;
      const brightnessValid = avgBrightness > 30 && avgBrightness < 225;
      
      // Calculate sharpness using standard deviation
      const avgStdDev = stats.channels.reduce((sum, ch) => sum + ch.stdev, 0) / stats.channels.length;
      const sharpnessScore = Math.min(avgStdDev / 50, 1); // Normalize to 0-1
      
      return {
        width,
        height,
        format,
        aspectRatio: parseFloat(aspectRatio.toFixed(2)),
        resolutionValid,
        aspectRatioValid,
        brightnessValid,
        brightness: Math.round(avgBrightness),
        sharpness: parseFloat(sharpnessScore.toFixed(2)),
        qualityScore: parseFloat(((resolutionValid ? 0.3 : 0) + 
                                   (aspectRatioValid ? 0.3 : 0) + 
                                   (brightnessValid ? 0.2 : 0) + 
                                   (sharpnessScore * 0.2)).toFixed(2)),
      };
    } catch (error) {
      console.error('❌ Image quality analysis failed:', error);
      throw error;
    }
  }

  /**
   * Validate document template/layout
   */
  async validateTemplate(imagePath, documentType = 'ID_CARD') {
    try {
      // Get image buffer
      const imageBuffer = await sharp(imagePath)
        .grayscale()
        .toBuffer();
      
      // Detect edges (simple edge detection)
      const edgeDetection = await sharp(imageBuffer)
        .convolve({
          width: 3,
          height: 3,
          kernel: [-1, -1, -1, -1, 8, -1, -1, -1, -1]
        })
        .toBuffer();
      
      const edgeStats = await sharp(edgeDetection).stats();
      const edgeDensity = edgeStats.channels[0].mean / 255;
      
      // Template score based on edge density
      // Valid documents typically have structured layouts with clear borders
      const templateScore = edgeDensity > 0.1 && edgeDensity < 0.5 ? 0.8 : 0.5;
      
      return {
        formatValid: true,
        templateScore: parseFloat(templateScore.toFixed(2)),
        edgeDensity: parseFloat(edgeDensity.toFixed(2)),
        hasStructure: edgeDensity > 0.1,
      };
    } catch (error) {
      console.error('❌ Template validation failed:', error);
      return {
        formatValid: false,
        templateScore: 0.3,
        error: error.message,
      };
    }
  }

  /**
   * Full document validation
   */
  async validateDocument(imagePath, ocrFields, documentType = 'ID_CARD') {
    try {
      console.log(`🔍 Validating document: ${documentType}`);
      
      const results = {};
      
      // 1. Image Quality Analysis
      results.imageQuality = await this.analyzeImageQuality(imagePath);
      
      // 2. Template Validation
      results.templateValidation = await this.validateTemplate(imagePath, documentType);
      
      // 3. Field Validations
      results.fieldValidation = {};
      
      if (ocrFields.id_number) {
        results.fieldValidation.idNumber = {
          value: ocrFields.id_number,
          valid: this.validateIDNumber(ocrFields.id_number, documentType),
        };
      }
      
      if (ocrFields.dob) {
        results.fieldValidation.dob = {
          value: ocrFields.dob,
          ...this.validateDate(ocrFields.dob),
        };
      }
      
      if (ocrFields.expiry_date) {
        results.fieldValidation.expiry = {
          value: ocrFields.expiry_date,
          ...this.validateExpiryDate(ocrFields.expiry_date),
        };
      }
      
      if (ocrFields.dob) {
        results.fieldValidation.age = this.validateAgeConsistency(ocrFields.dob);
      }
      
      // 4. Calculate overall validation score - STRICTER
      const scores = [];
      
      // Image quality score (weighted heavily)
      scores.push(results.imageQuality.qualityScore * 1.5);
      
      // Template validation (weighted heavily)
      scores.push(results.templateValidation.templateScore * 1.5);
      
      // Field validations
      if (results.fieldValidation.idNumber) {
        scores.push(results.fieldValidation.idNumber.valid ? 1 : 0);
      } else {
        scores.push(0); // Penalize missing ID
      }
      
      if (results.fieldValidation.dob) {
        scores.push(results.fieldValidation.dob.valid ? 1 : 0);
      } else {
        scores.push(0); // Penalize missing DOB
      }
      
      if (results.fieldValidation.expiry) {
        scores.push(results.fieldValidation.expiry.valid && !results.fieldValidation.expiry.expired ? 1 : 0);
      }
      
      // Calculate average with stricter requirements
      const avgScore = scores.reduce((a, b) => a + b, 0) / scores.length;
      results.overallScore = parseFloat(Math.min(1, avgScore).toFixed(2));
      results.validationPassed = results.overallScore >= 0.7; // Raised from 0.6
      
      console.log(`✅ Validation complete - Score: ${results.overallScore} (Passed: ${results.validationPassed})`);

      
      return results;
    } catch (error) {
      console.error('❌ Document validation failed:', error);
      throw error;
    }
  }
}

module.exports = new DocumentValidator();
