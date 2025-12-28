const sharp = require('sharp');
let createCanvas, loadImage;

// Try to load canvas, but make it optional
try {
  const canvasModule = require('canvas');
  createCanvas = canvasModule.createCanvas;
  loadImage = canvasModule.loadImage;
} catch (error) {
  console.warn('⚠️ Canvas module not available - some forensics features will be limited');
}

class ImageForensics {
  /**
   * Detect copy-paste artifacts using noise analysis
   */
  async detectCopyPasteArtifacts(imagePath) {
    try {
      const image = await sharp(imagePath);
      const { width, height } = await image.metadata();
      
      // Divide image into grid (4x4)
      const gridSize = 4;
      const cellWidth = Math.floor(width / gridSize);
      const cellHeight = Math.floor(height / gridSize);
      
      // Validate image is large enough
      if (cellWidth < 10 || cellHeight < 10) {
        return {
          tampered: false,
          inconsistencyScore: 0,
          noiseVariances: [],
        };
      }
      
      const noiseVariances = [];
      
      for (let i = 0; i < gridSize; i++) {
        for (let j = 0; j < gridSize; j++) {
          const left = i * cellWidth;
          const top = j * cellHeight;
          
          // Ensure extraction stays within bounds
          const extractWidth = Math.min(cellWidth, width - left);
          const extractHeight = Math.min(cellHeight, height - top);
          
          if (extractWidth < 1 || extractHeight < 1) continue;
          
          const cell = await image
            .extract({ left, top, width: extractWidth, height: extractHeight })
            .grayscale()
            .raw()
            .toBuffer();
          
          // Calculate noise variance for this cell
          const variance = this.calculateVariance(Array.from(cell));
          noiseVariances.push(variance);
        }
      }
      
      if (noiseVariances.length === 0) {
        return {
          tampered: false,
          inconsistencyScore: 0,
          noiseVariances: [],
        };
      }
      
      // Calculate standard deviation of variances
      const mean = noiseVariances.reduce((a, b) => a + b) / noiseVariances.length;
      const stdDev = Math.sqrt(
        noiseVariances.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / noiseVariances.length
      );
      
      // High std dev indicates inconsistent noise (possible tampering)
      const inconsistencyScore = Math.min(stdDev / 1000, 1);
      const tampered = inconsistencyScore > 0.3;
      
      return {
        tampered,
        inconsistencyScore: parseFloat(inconsistencyScore.toFixed(2)),
        noiseVariances: noiseVariances.map(v => parseFloat(v.toFixed(2))),
      };
    } catch (error) {
      console.error('❌ Copy-paste detection failed:', error);
      return { tampered: false, inconsistencyScore: 0, error: error.message };
    }
  }

  /**
   * Detect blur inconsistencies
   */
  async detectBlurInconsistencies(imagePath) {
    try {
      const image = await sharp(imagePath);
      const { width, height } = await image.metadata();
      
      // Divide into 3x3 grid
      const gridSize = 3;
      const cellWidth = Math.floor(width / gridSize);
      const cellHeight = Math.floor(height / gridSize);
      
      // Ensure dimensions are valid
      if (cellWidth < 1 || cellHeight < 1) {
        console.warn('⚠️ Image too small for blur detection');
        return { tampered: false, blurInconsistency: 0, blurScores: [] };
      }
      
      const blurScores = [];
      
      for (let i = 0; i < gridSize; i++) {
        for (let j = 0; j < gridSize; j++) {
          const left = i * cellWidth;
          const top = j * cellHeight;
          
          // Ensure we don't exceed image bounds
          const extractWidth = Math.min(cellWidth, width - left);
          const extractHeight = Math.min(cellHeight, height - top);
          
          if (extractWidth < 1 || extractHeight < 1) continue;
          
          const cell = await image
            .extract({ left, top, width: extractWidth, height: extractHeight })
            .grayscale()
            .raw()
            .toBuffer();
          
          // Calculate Laplacian variance (blur metric)
          const blurScore = this.calculateLaplacianVariance(Array.from(cell), extractWidth);
          blurScores.push(blurScore);
        }
      }
      
      if (blurScores.length === 0) {
        return { tampered: false, blurInconsistency: 0, blurScores: [] };
      }
      
      // Calculate coefficient of variation
      const mean = blurScores.reduce((a, b) => a + b) / blurScores.length;
      const stdDev = Math.sqrt(
        blurScores.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / blurScores.length
      );
      const coefficientOfVariation = stdDev / mean;
      
      // High CV indicates inconsistent blur
      const tampered = coefficientOfVariation > 0.5;
      
      return {
        tampered,
        blurInconsistency: parseFloat(coefficientOfVariation.toFixed(2)),
        blurScores: blurScores.map(s => parseFloat(s.toFixed(2))),
      };
    } catch (error) {
      console.error('❌ Blur detection failed:', error);
      return { tampered: false, blurInconsistency: 0, error: error.message };
    }
  }

  /**
   * Detect sharpness mismatch using edge detection
   */
  async detectSharpnessMismatch(imagePath) {
    try {
      const edges = await sharp(imagePath)
        .grayscale()
        .convolve({
          width: 3,
          height: 3,
          kernel: [-1, -1, -1, -1, 8, -1, -1, -1, -1]
        })
        .toBuffer();
      
      const stats = await sharp(edges).stats();
      const edgeStrength = stats.channels[0].mean;
      
      // Analyze edge distribution
      const { width, height } = await sharp(imagePath).metadata();
      const gridSize = 3;
      const cellWidth = Math.floor(width / gridSize);
      const cellHeight = Math.floor(height / gridSize);
      
      // Validate image is large enough
      if (cellWidth < 1 || cellHeight < 1) {
        return { tampered: false, sharpnessMismatch: 0, edgeStrength };
      }
      
      const sharpnessScores = [];
      
      for (let i = 0; i < gridSize; i++) {
        for (let j = 0; j < gridSize; j++) {
          const left = i * cellWidth;
          const top = j * cellHeight;
          
          // Ensure extraction stays within bounds
          const extractWidth = Math.min(cellWidth, width - left);
          const extractHeight = Math.min(cellHeight, height - top);
          
          if (extractWidth < 1 || extractHeight < 1) continue;
          
          const cell = await sharp(edges)
            .extract({ left, top, width: extractWidth, height: extractHeight })
            .raw()
            .toBuffer();
          
          const cellSharpness = Array.from(cell).reduce((a, b) => a + b) / cell.length;
          sharpnessScores.push(cellSharpness);
        }
      }
      
      if (sharpnessScores.length === 0) {
        return { tampered: false, sharpnessMismatch: 0, edgeStrength };
      }
      
      // Calculate variation
      const mean = sharpnessScores.reduce((a, b) => a + b) / sharpnessScores.length;
      const stdDev = Math.sqrt(
        sharpnessScores.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / sharpnessScores.length
      );
      const mismatchScore = stdDev / mean;
      
      const tampered = mismatchScore > 0.4;
      
      return {
        tampered,
        sharpnessMismatch: parseFloat(mismatchScore.toFixed(2)),
        edgeStrength: parseFloat(edgeStrength.toFixed(2)),
      };
    } catch (error) {
      console.error('❌ Sharpness detection failed:', error);
      return { tampered: false, sharpnessMismatch: 0, error: error.message };
    }
  }

  /**
   * Detect double JPEG compression artifacts
   */
  async detectDoubleJPEG(imagePath) {
    try {
      const metadata = await sharp(imagePath).metadata();
      
      // Check if JPEG
      if (metadata.format !== 'jpeg' && metadata.format !== 'jpg') {
        return { tampered: false, reason: 'Not a JPEG image' };
      }
      
      // Recompress and compare
      const original = await sharp(imagePath).toBuffer();
      const recompressed = await sharp(imagePath).jpeg({ quality: 95 }).toBuffer();
      
      // Calculate size difference
      const sizeDiff = Math.abs(original.length - recompressed.length) / original.length;
      
      // Small size difference might indicate double compression
      const tampered = sizeDiff < 0.05;
      
      return {
        tampered,
        compressionArtifacts: parseFloat(sizeDiff.toFixed(3)),
        originalSize: original.length,
        recompressedSize: recompressed.length,
      };
    } catch (error) {
      console.error('❌ JPEG detection failed:', error);
      return { tampered: false, error: error.message };
    }
  }

  /**
   * Helper: Calculate variance of array
   */
  calculateVariance(arr) {
    const mean = arr.reduce((a, b) => a + b) / arr.length;
    return arr.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / arr.length;
  }

  /**
   * Helper: Calculate Laplacian variance (blur metric)
   */
  calculateLaplacianVariance(pixels, width) {
    const laplacian = [];
    
    for (let i = width; i < pixels.length - width; i++) {
      if (i % width !== 0 && i % width !== width - 1) {
        const lap = Math.abs(
          -pixels[i - width - 1] - pixels[i - width] - pixels[i - width + 1] -
          pixels[i - 1] + 8 * pixels[i] - pixels[i + 1] -
          pixels[i + width - 1] - pixels[i + width] - pixels[i + width + 1]
        );
        laplacian.push(lap);
      }
    }
    
    return this.calculateVariance(laplacian);
  }

  /**
   * Full forensic analysis
   */
  async analyzeImage(imagePath) {
    try {
      console.log(`🔬 Starting forensic analysis: ${imagePath}`);
      
      const [copyPaste, blur, sharpness, jpeg] = await Promise.all([
        this.detectCopyPasteArtifacts(imagePath),
        this.detectBlurInconsistencies(imagePath),
        this.detectSharpnessMismatch(imagePath),
        this.detectDoubleJPEG(imagePath),
      ]);
      
      // Count tampering indicators
      const tamperedCount = [
        copyPaste.tampered,
        blur.tampered,
        sharpness.tampered,
        jpeg.tampered,
      ].filter(Boolean).length;
      
      // Calculate overall tampering score (0-1)
      const tamperScore = tamperedCount / 4;
      
      const result = {
        tampered: tamperedCount >= 2, // At least 2 indicators
        tamperScore: parseFloat(tamperScore.toFixed(2)),
        indicators: {
          copyPasteArtifacts: copyPaste,
          blurInconsistencies: blur,
          sharpnessMismatch: sharpness,
          doubleJPEG: jpeg,
        },
        tamperedCount,
      };
      
      console.log(`✅ Forensics complete - Tampered: ${result.tampered} (Score: ${result.tamperScore})`);
      
      return result;
    } catch (error) {
      console.error('❌ Forensic analysis failed:', error);
      throw error;
    }
  }
}

module.exports = new ImageForensics();
