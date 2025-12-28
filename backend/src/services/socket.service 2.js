let io = null;

// Initialize socket instance
exports.init = (socketIO) => {
  io = socketIO;
};

// Emit SOS alert to all guards
exports.emitSOSAlert = (sosEvent) => {
  if (!io) return;
  
  io.emit('sos:new', {
    type: 'new_alert',
    data: {
      id: sosEvent._id,
      userName: sosEvent.userName,
      flatNumber: sosEvent.flatNumber,
      timestamp: sosEvent.createdAt,
      latitude: sosEvent.latitude,
      longitude: sosEvent.longitude,
      status: sosEvent.status,
      description: sosEvent.description,
      priority: 'high'
    }
  });
};

// Emit SOS update (acknowledged/resolved)
exports.emitSOSUpdate = (sosEvent) => {
  if (!io) return;
  
  io.emit('sos:update', {
    type: 'status_update',
    data: {
      id: sosEvent._id,
      status: sosEvent.status,
      guardId: sosEvent.guardId,
      acknowledgedAt: sosEvent.acknowledgedAt,
      resolvedAt: sosEvent.resolvedAt,
      resolutionNotes: sosEvent.resolutionNotes
    }
  });
};

// Emit to specific room
exports.emitToRoom = (room, event, data) => {
  if (!io) return;
  io.to(room).emit(event, data);
};

// Emit globally
exports.emitGlobal = (event, data) => {
  if (!io) return;
  io.emit(event, data);
};