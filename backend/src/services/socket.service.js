// Socket.IO service for real-time events
let io;

const socketService = {
  // Initialize socket.io instance
  init(socketIo) {
    io = socketIo;
    console.log('Socket.IO service initialized');
  },

  // Get socket.io instance
  getIO() {
    if (!io) {
      throw new Error('Socket.IO not initialized!');
    }
    return io;
  },

  // Emit SOS alert to guards and police
  emitSOSAlert(sosEvent) {
    if (io) {
      console.log('📡 Emitting SOS alert...');
      console.log('   Event:', 'police:sos-alert');
      
      // Sanitize event before emitting - remove blockchainHash
      const sanitizedEvent = { ...sosEvent };
      delete sanitizedEvent.blockchainHash;
      
      console.log('   Data:', JSON.stringify(sanitizedEvent, null, 2));
      
      // Emit to guards room
      io.to('guards').emit('sos:new', sanitizedEvent);
      console.log('   ✅ Emitted to guards room');
      
      // Emit to police room
      io.to('police').emit('police:sos-alert', sanitizedEvent);
      console.log('   ✅ Emitted police:sos-alert to police room');
      
      // Emit to society room if societyId exists
      if (sosEvent.societyId) {
        io.to(sosEvent.societyId).emit('sos:new', sanitizedEvent);
        console.log(`   ✅ Emitted to society ${sosEvent.societyId}`);
      }
      
      console.log('🚨 SOS alert emitted to police and guards:', sosEvent._id);
    } else {
      console.error('❌ Socket.IO not initialized!');
    }
  },

  // Emit SOS update
  emitSOSUpdate(sosEvent) {
    if (io) {
      // Sanitize event before emitting - remove blockchainHash
      const sanitizedEvent = { ...sosEvent };
      delete sanitizedEvent.blockchainHash;
      
      // Emit to guards room
      io.to('guards').emit('sos:update', sanitizedEvent);
      
      // Emit to society room
      if (sosEvent.societyId) {
        io.to(sosEvent.societyId).emit('sos:update', sanitizedEvent);
      }
      
      console.log('SOS update emitted:', sosEvent._id);
    }
  },

  // Emit to specific room
  emitToRoom(room, event, data) {
    if (io) {
      io.to(room).emit(event, data);
    }
  },

  // Broadcast to all connected clients
  broadcast(event, data) {
    if (io) {
      io.emit(event, data);
    }
  }
};

module.exports = socketService;
