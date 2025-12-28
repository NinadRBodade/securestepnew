const Tesseract = require('tesseract.js');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;

class OCRService {
  constructor() {
    this.worker = null;
  }

  /**
   * Initialize Tesseract worker
   */
  async initialize() {
    if (!this.worker) {
      this.worker = await Tesseract.createWorker('eng');
      console.log('✅ OCR Worker initialized');
    }
  }

  /**
   * Preprocess image for better OCR accuracy
   */
  async preprocessImage(imagePath) {
    try {
      const preprocessedPath = imagePath.replace(/\.(jpg|jpeg|png)$/i, '_processed.png');
      
      await sharp(imagePath)
        .grayscale() // Convert to grayscale
        .normalize() // Enhance contrast
        .sharpen() // Sharpen text
        .threshold(128) // Binary threshold
        .toFile(preprocessedPath);
      
      console.log(`✅ Image preprocessed: ${preprocessedPath}`);
      return preprocessedPath;
    } catch (error) {
      console.error('❌ Image preprocessing failed:', error);
      return imagePath; // Return original if preprocessing fails
    }
  }

  /**
   * Extract text from document image
   */
  async extractText(imagePath) {
    try {
      await this.initialize();
      
      // Preprocess image
      const processedPath = await this.preprocessImage(imagePath);
      
      // Perform OCR
      const { data } = await this.worker.recognize(processedPath);
      
      // Clean up preprocessed image
      if (processedPath !== imagePath) {
        await fs.unlink(processedPath).catch(() => {});
      }
      
      return {
        text: data.text,
        confidence: data.confidence,
        words: data.words,
        lines: data.lines,
      };
    } catch (error) {
      console.error('❌ OCR extraction failed:', error);
      throw new Error(`OCR failed: ${error.message}`);
    }
  }

  /**
   * Parse structured fields from OCR text
   */
  parseFields(ocrText, documentType = 'ID_CARD') {
    const fields = {};
    const text = ocrText.toLowerCase();

    // Extract Name (various patterns)
    const namePatterns = [
      /name[:\s]*([a-z\s]+)/i,
      /holder[:\s]*([a-z\s]+)/i,
      /full name[:\s]*([a-z\s]+)/i,
    ];
    
    for (const pattern of namePatterns) {
      const match = ocrText.match(pattern);
      if (match) {
        fields.name = match[1].trim();
        break;
      }
    }

    // Extract ID Number
    const idPatterns = [
      /(?:id|identification|card)[\s#:]*([A-Z0-9]{6,20})/i,
      /(?:number|no|#)[\s:]*([A-Z0-9]{6,20})/i,
      /\b([A-Z]{2}[0-9]{6,15})\b/i, // Pattern like AB123456789
    ];
    
    for (const pattern of idPatterns) {
      const match = ocrText.match(pattern);
      if (match) {
        fields.id_number = match[1].trim();
        break;
      }
    }

    // Extract Date of Birth
    const dobPatterns = [
      /(?:dob|date of birth|born)[\s:]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/i,
      /(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/,
    ];
    
    for (const pattern of dobPatterns) {
      const match = ocrText.match(pattern);
      if (match) {
        fields.dob = this.normalizeDate(match[1]);
        break;
      }
    }

    // Extract Expiry Date
    const expiryPatterns = [
      /(?:expiry|expires|valid until)[\s:]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/i,
      /(?:exp|expiration)[\s:]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/i,
    ];
    
    for (const pattern of expiryPatterns) {
      const match = ocrText.match(pattern);
      if (match) {
        fields.expiry_date = this.normalizeDate(match[1]);
        break;
      }
    }

    // Extract Gender
    if (/\b(male|m)\b/i.test(ocrText) && !/female/i.test(ocrText)) {
      fields.gender = 'Male';
    } else if (/\b(female|f)\b/i.test(ocrText)) {
      fields.gender = 'Female';
    }

    // Extract Address (multiline)
    const addressMatch = ocrText.match(/address[:\s]*([\s\S]{20,150}?)(?=\n\n|\n[A-Z]|$)/i);
    if (addressMatch) {
      fields.address = addressMatch[1].replace(/\s+/g, ' ').trim();
    }

    // Document Type
    fields.document_type = documentType;

    return fields;
  }

  /**
   * Normalize date format to YYYY-MM-DD
   */
  normalizeDate(dateStr) {
    try {
      // Handle various formats: DD/MM/YYYY, MM-DD-YYYY, etc.
      const parts = dateStr.split(/[\/\-\.]/);
      
      if (parts.length === 3) {
        let [first, second, third] = parts;
        
        // If third part is 2 digits, assume it's YY and convert to YYYY
        if (third.length === 2) {
          third = (parseInt(third) > 50 ? '19' : '20') + third;
        }
        
        // Assume DD/MM/YYYY format (common in many countries)
        if (parseInt(first) <= 31) {
          return `${third}-${second.padStart(2, '0')}-${first.padStart(2, '0')}`;
        } else {
          // Assume YYYY-MM-DD
          return `${first}-${second.padStart(2, '0')}-${third.padStart(2, '0')}`;
        }
      }
      
      return dateStr;
    } catch (error) {
      return dateStr;
    }
  }

  /**
   * Full OCR analysis with field extraction
   */
  async analyzeDocument(imagePath, documentType = 'ID_CARD') {
    try {
      console.log(`🔍 Starting OCR analysis for: ${imagePath}`);
      
      // Extract text
      const ocrResult = await this.extractText(imagePath);
      
      // Parse fields
      const fields = this.parseFields(ocrResult.text, documentType);
      
      // Calculate completeness score
      const requiredFields = ['name', 'id_number', 'dob'];
      const foundFields = requiredFields.filter(f => fields[f]);
      const completeness = foundFields.length / requiredFields.length;
      
      // Quality score based on confidence
      const qualityScore = ocrResult.confidence / 100;
      
      console.log(`✅ OCR completed with ${ocrResult.confidence}% confidence`);
      console.log(`📝 Extracted fields:`, fields);
      
      return {
        fields,
        ocrConfidence: parseFloat((ocrResult.confidence / 100).toFixed(2)),
        qualityScore: parseFloat(qualityScore.toFixed(2)),
        completeness: parseFloat(completeness.toFixed(2)),
        rawText: ocrResult.text,
        wordCount: ocrResult.words?.length || 0,
      };
    } catch (error) {
      console.error('❌ Document analysis failed:', error);
      // Return safe defaults instead of throwing
      return {
        fields: {},
        ocrConfidence: 0,
        qualityScore: 0,
        completeness: 0,
        rawText: '',
        wordCount: 0,
      };
    }
  }

  /**
   * Cleanup worker
   */
  async terminate() {
    if (this.worker) {
      await this.worker.terminate();
      this.worker = null;
      console.log('🛑 OCR Worker terminated');
    }
  }
}

// Singleton instance
const ocrService = new OCRService();

module.exports = ocrService;
