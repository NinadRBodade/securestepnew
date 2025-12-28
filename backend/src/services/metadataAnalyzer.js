const { exiftool } = require('exiftool-vendored');
const sharp = require('sharp');

class MetadataAnalyzer {
  constructor() {
    this.editingSoftwareKeywords = [
      'photoshop',
      'gimp',
      'paint.net',
      'pixlr',
      'canva',
      'lightroom',
      'snapseed',
      'vsco',
      'picsart',
      'adobe',
    ];
  }

  /**
   * Extract EXIF metadata from image
   */
  async extractMetadata(imagePath) {
    try {
      const metadata = await exiftool.read(imagePath);
      
      return {
        make: metadata.Make,
        model: metadata.Model,
        software: metadata.Software,
        dateTime: metadata.DateTimeOriginal || metadata.CreateDate,
        gps: {
          latitude: metadata.GPSLatitude,
          longitude: metadata.GPSLongitude,
        },
        width: metadata.ImageWidth,
        height: metadata.ImageHeight,
        orientation: metadata.Orientation,
        colorSpace: metadata.ColorSpace,
        compression: metadata.Compression,
        all: metadata,
      };
    } catch (error) {
      console.error('❌ EXIF extraction failed:', error);
      return null;
    }
  }

  /**
   * Detect if image was edited
   */
  detectEditingSoftware(metadata) {
    if (!metadata) return { detected: false, software: null };
    
    const software = (metadata.software || '').toLowerCase();
    const creator = (metadata.all?.Creator || '').toLowerCase();
    const history = (metadata.all?.History || '').toLowerCase();
    
    const combinedText = `${software} ${creator} ${history}`;
    
    for (const keyword of this.editingSoftwareKeywords) {
      if (combinedText.includes(keyword)) {
        return {
          detected: true,
          software: keyword,
          field: software.includes(keyword) ? 'Software' : 'Creator/History',
        };
      }
    }
    
    return { detected: false, software: null };
  }

  /**
   * Detect if image is a screenshot
   */
  detectScreenshot(metadata, imagePath) {
    const indicators = {
      isScreenshot: false,
      reasons: [],
    };
    
    if (!metadata) return indicators;
    
    // Check software field
    const software = (metadata.software || '').toLowerCase();
    if (software.includes('screenshot') || software.includes('screen capture')) {
      indicators.isScreenshot = true;
      indicators.reasons.push('Software field indicates screenshot');
    }
    
    // Check if no camera make/model
    if (!metadata.make && !metadata.model) {
      indicators.reasons.push('Missing camera metadata');
    }
    
    // Check filename patterns
    const filename = imagePath.toLowerCase();
    if (filename.includes('screenshot') || filename.includes('screen_') || filename.includes('scr_')) {
      indicators.isScreenshot = true;
      indicators.reasons.push('Filename suggests screenshot');
    }
    
    return indicators;
  }

  /**
   * Check for camera metadata
   */
  hasCameraMetadata(metadata) {
    if (!metadata) return false;
    
    const hasMake = !!metadata.make;
    const hasModel = !!metadata.model;
    const hasDateTime = !!metadata.dateTime;
    const hasGPS = !!(metadata.gps?.latitude && metadata.gps?.longitude);
    
    return {
      hasCameraInfo: hasMake || hasModel,
      hasDateTime,
      hasGPS,
      make: metadata.make,
      model: metadata.model,
      score: (hasMake ? 0.4 : 0) + (hasModel ? 0.4 : 0) + (hasDateTime ? 0.2 : 0),
    };
  }

  /**
   * Analyze metadata risk
   */
  async analyzeMetadata(imagePath) {
    try {
      console.log(`📊 Analyzing metadata: ${imagePath}`);
      
      // Extract metadata
      const metadata = await this.extractMetadata(imagePath);
      
      // Check for editing software
      const editingSoftware = this.detectEditingSoftware(metadata);
      
      // Check for screenshot
      const screenshot = this.detectScreenshot(metadata, imagePath);
      
      // Check camera metadata
      const cameraInfo = this.hasCameraMetadata(metadata);
      
      // Calculate risk
      let riskScore = 0;
      const riskFactors = [];
      
      if (editingSoftware.detected) {
        riskScore += 40;
        riskFactors.push(`Editing software detected: ${editingSoftware.software}`);
      }
      
      if (screenshot.isScreenshot) {
        riskScore += 50;
        riskFactors.push('Image appears to be a screenshot');
      }
      
      if (!cameraInfo.hasCameraInfo) {
        riskScore += 30;
        riskFactors.push('Missing camera metadata');
      }
      
      // Determine risk level
      let metadataRisk = 'LOW';
      if (riskScore >= 70) {
        metadataRisk = 'HIGH';
      } else if (riskScore >= 40) {
        metadataRisk = 'MEDIUM';
      }
      
      const result = {
        metadataRisk,
        hasEditingSoftware: editingSoftware.detected,
        editingSoftwareDetails: editingSoftware.detected ? editingSoftware : null,
        isScreenshot: screenshot.isScreenshot,
        screenshotReasons: screenshot.reasons,
        hasCameraMetadata: cameraInfo.hasCameraInfo,
        cameraDetails: cameraInfo,
        riskScore,
        riskFactors,
        details: metadata,
      };
      
      console.log(`✅ Metadata analysis complete - Risk: ${metadataRisk} (${riskScore})`);
      
      return result;
    } catch (error) {
      console.error('❌ Metadata analysis failed:', error);
      return {
        metadataRisk: 'MEDIUM',
        hasEditingSoftware: false,
        isScreenshot: false,
        hasCameraMetadata: false,
        riskScore: 50,
        riskFactors: ['Analysis failed - defaulting to medium risk'],
        error: error.message,
      };
    }
  }

  /**
   * Cleanup
   */
  async close() {
    try {
      await exiftool.end();
      console.log('🛑 ExifTool closed');
    } catch (error) {
      console.error('Error closing ExifTool:', error);
    }
  }
}

module.exports = new MetadataAnalyzer();
