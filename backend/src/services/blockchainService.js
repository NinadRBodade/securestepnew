const crypto = require('crypto');

/**
 * Blockchain-style Service for SOS Data Integrity Verification
 * Uses SHA-256 hashing to detect tampering
 * NO cryptocurrency, NO Ethereum, NO smart contracts
 */

class BlockchainService {
  /**
   * Extract immutable fields for hash payload
   * Only these fields are used for integrity verification
   * Normalizes all values to ensure consistent hashing
   * @param {Object} sosData - SOS record data
   * @returns {Object} - Hash payload with immutable fields only
   */
  getHashPayload(sosData) {
    // Normalize date to ISO string for consistent hashing
    const triggeredAt = sosData.triggeredAt instanceof Date 
      ? sosData.triggeredAt.toISOString() 
      : sosData.triggeredAt;
    
    return {
      sosId: sosData.sosId,
      userId: sosData.userId,
      flatNumber: sosData.flatNumber,
      latitude: sosData.latitude || null,
      longitude: sosData.longitude || null,
      description: sosData.description,
      triggeredAt: triggeredAt
    };
  }

  /**
   * Generate SHA-256 hash for SOS data
   * @param {Object} sosData - SOS record data (MongoDB format)
   * @returns {String} - SHA-256 hash
   */
  generateHash(sosData) {
    try {
      // Use only immutable fields for hashing
      const payload = this.getHashPayload(sosData);
      
      // Create deterministic string from payload
      const dataString = JSON.stringify(payload);

      // Generate SHA-256 hash using Node.js built-in crypto
      const hash = crypto
        .createHash('sha256')
        .update(dataString)
        .digest('hex');

      console.log('🔐 Generated blockchain hash:', hash.substring(0, 16) + '...');
      return hash;
    } catch (error) {
      console.error('❌ Hash generation error:', error);
      return null;
    }
  }

  /**
   * Verify SOS data integrity by comparing hashes
   * @param {Object} sosData - Current SOS record
   * @param {String} storedHash - Hash stored in database
   * @returns {Object} - Verification result
   */
  verifyHash(sosData, storedHash) {
    try {
      // Regenerate hash from current data
      const currentHash = this.generateHash(sosData);

      // Compare with stored hash
      const isVerified = currentHash === storedHash;

      return {
        verified: isVerified,
        message: isVerified 
          ? '✅ Data is authentic - No tampering detected' 
          : '⚠️ Data has been tampered - Hash mismatch detected',
        currentHash,
        storedHash
      };
    } catch (error) {
      console.error('❌ Hash verification error:', error);
      return {
        verified: false,
        message: '❌ Verification failed - Error occurred',
        error: error.message
      };
    }
  }

  /**
   * Generate hash chain for multiple SOS records
   * Links records together for enhanced integrity
   * @param {Array} sosRecords - Array of SOS records
   * @returns {Array} - Records with hash chain
   */
  generateHashChain(sosRecords) {
    let previousHash = '0'; // Genesis hash

    return sosRecords.map(record => {
      const dataWithPrevious = {
        ...record,
        previousHash
      };
      
      const hash = this.generateHash(dataWithPrevious);
      previousHash = hash;

      return {
        ...record,
        blockchainHash: hash,
        previousHash
      };
    });
  }
}

module.exports = new BlockchainService();
