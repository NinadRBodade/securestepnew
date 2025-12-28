const socketService = require('../services/socket.service');

// Initialize socket.io events
const initSocket = (io) => {
  // Initialize socket service with io instance
  socketService.init(io);
  
  io.on('connection', (socket) => {
    console.log('🔌 Socket connected:', socket.id);

    // Join police room (police dashboard auto-joins on connect)
    socket.join('police');
    console.log(`Socket ${socket.id} joined police room`);

    // Join society room
    socket.on('society:join', (societyId) => {
      socket.join(societyId);
      console.log(`Socket ${socket.id} joined society ${societyId}`);
    });

    // Join guard room for SOS alerts
    socket.on('guard:online', () => {
      socket.join('guards');
      console.log(`Guard ${socket.id} is now online`);
    });

    // Leave society room
    socket.on('society:leave', (societyId) => {
      socket.leave(societyId);
    });
    
    // Guard goes offline
    socket.on('guard:offline', () => {
      socket.leave('guards');
      console.log(`Guard ${socket.id} went offline`);
    });

    // Disconnect
    socket.on('disconnect', () => {
      console.log('🔌 Socket disconnected:', socket.id);
    });
  });
};

// Export both initSocket and emitSOSAlert for use in controllers
module.exports = initSocket;
module.exports.emitSOSAlert = (sosEvent) => {
  socketService.emitSOSAlert(sosEvent);
};