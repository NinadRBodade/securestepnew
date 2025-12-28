const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');

async function generateAgentQR(agentData) {
  try {
    const qrId = uuidv4();
    
    const qrData = {
      id: qrId,
      agentId: agentData._id || agentData.id,
      type: 'agent',
      timestamp: new Date().toISOString()
    };
    
    const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData), {
      errorCorrectionLevel: 'H',
      type: 'image/png',
      quality: 0.92,
      margin: 1,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
    
    return {
      qrId,
      qrCode: qrCodeDataURL,
      qrData
    };
  } catch (error) {
    throw new Error(`QR Code generation failed: ${error.message}`);
  }
}

async function generateAgentQRBuffer(agentData) {
  try {
    const qrId = uuidv4();
    
    const qrData = {
      id: qrId,
      agentId: agentData._id || agentData.id,
      type: 'agent',
      timestamp: new Date().toISOString()
    };
    
    const qrBuffer = await QRCode.toBuffer(JSON.stringify(qrData), {
      errorCorrectionLevel: 'H',
      type: 'png',
      quality: 0.92,
      margin: 1
    });
    
    return {
      qrId,
      qrBuffer,
      qrData
    };
  } catch (error) {
    throw new Error(`QR Code buffer generation failed: ${error.message}`);
  }
}

function decodeQRData(qrDataString) {
  try {
    return JSON.parse(qrDataString);
  } catch (error) {
    throw new Error('Invalid QR code data');
  }
}

module.exports = {
  generateAgentQR,
  generateAgentQRBuffer,
  decodeQRData
};
