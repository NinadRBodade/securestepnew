import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../models/sos_event_model.dart';
import '../config/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  bool _isConnected = false;
  
  final _sosAlertsController = StreamController<List<SOSEvent>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  List<SOSEvent> _cachedAlerts = [];

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  /// Get stream of SOS alerts
  Stream<List<SOSEvent>> get sosAlerts => _sosAlertsController.stream;
  
  /// Get connection status stream
  Stream<bool> get connectionStatus => _connectionController.stream;
  
  /// Check if connected
  bool get isConnected => _isConnected;

  /// Initialize Socket.IO connection
  Future<void> connect(String token) async {
    try {
      if (_socket != null && _socket!.connected) {
        print('✅ Already connected to Socket.IO');
        return;
      }

      // Extract base URL without trailing slash
      String baseUrl = ApiConfig.baseUrl;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      print('🔄 Connecting to Socket.IO at: $baseUrl');

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      // Connection events
      _socket!.onConnect((_) {
        print('✅ Connected to Socket.IO');
        _isConnected = true;
        _connectionController.add(true);
        _joinGuardsRoom();
      });

      _socket!.onDisconnect((_) {
        print('❌ Disconnected from Socket.IO');
        _isConnected = false;
        _connectionController.add(false);
      });

      _socket!.onConnectError((error) {
        print('❌ Socket.IO connection error: $error');
        _isConnected = false;
        _connectionController.add(false);
      });

      // Listen to new SOS alerts
      _socket!.on('sos:new', (data) {
        print('📨 Received new SOS alert via Socket.IO');
        print('Data: $data');
        try {
          final sosEvent = SOSEvent.fromJson(data);
          _addAlert(sosEvent);
          print('✅ Added SOS alert to stream');
        } catch (e) {
          print('❌ Error parsing SOS alert: $e');
        }
      });

      // Listen to SOS updates
      _socket!.on('sos:update', (data) {
        print('📨 Received SOS update via Socket.IO');
        try {
          final sosEvent = SOSEvent.fromJson(data);
          _updateAlert(sosEvent);
          print('✅ Updated SOS alert in stream');
        } catch (e) {
          print('❌ Error parsing SOS update: $e');
        }
      });

      // Listen to SOS acknowledgements
      _socket!.on('sos:acknowledged', (data) {
        print('📨 Received SOS acknowledgement via Socket.IO');
        try {
          final sosEvent = SOSEvent.fromJson(data);
          _updateAlert(sosEvent);
        } catch (e) {
          print('❌ Error parsing acknowledgement: $e');
        }
      });

      // Listen to SOS resolutions
      _socket!.on('sos:resolved', (data) {
        print('📨 Received SOS resolution via Socket.IO');
        try {
          final sosEvent = SOSEvent.fromJson(data);
          if (sosEvent.id != null) {
            _removeAlert(sosEvent.id!);
          }
        } catch (e) {
          print('❌ Error parsing resolution: $e');
        }
      });

      // Handle custom events
      _socket!.on('notification', (data) {
        print('📨 Received notification: $data');
      });

      _socket!.connect();
      print('🔌 Socket.IO connect initiated');
    } catch (e) {
      print('❌ Socket.IO initialization error: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// Join guards room to receive SOS alerts
  void _joinGuardsRoom() {
    if (_socket != null && _socket!.connected) {
      print('👥 Joining guards room...');
      _socket!.emit('join-room', {'room': 'guards'});
    }
  }

  /// Add alert to cached list and emit to stream
  void _addAlert(SOSEvent alert) {
    // Remove if already exists (update instead of duplicate)
    _cachedAlerts.removeWhere((a) => a.id == alert.id);
    
    // Add new alert at the beginning (most recent first)
    _cachedAlerts.insert(0, alert);
    
    // Keep only last 100 alerts
    if (_cachedAlerts.length > 100) {
      _cachedAlerts = _cachedAlerts.sublist(0, 100);
    }
    
    _sosAlertsController.add(List.from(_cachedAlerts));
  }

  /// Update alert in cached list
  void _updateAlert(SOSEvent alert) {
    final index = _cachedAlerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      _cachedAlerts[index] = alert;
      _sosAlertsController.add(List.from(_cachedAlerts));
      print('✅ Alert updated: ${alert.id}');
    }
  }

  /// Remove alert from cached list
  void _removeAlert(String alertId) {
    _cachedAlerts.removeWhere((a) => a.id == alertId);
    _sosAlertsController.add(List.from(_cachedAlerts));
    print('✅ Alert removed: $alertId');
  }

  /// Get cached alerts
  List<SOSEvent> getCachedAlerts() {
    return List.from(_cachedAlerts);
  }

  /// Emit acknowledgement for SOS
  void acknowledgeSOS(String sosId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sos:acknowledge', {'sosId': sosId});
      print('📤 Sent SOS acknowledgement: $sosId');
    }
  }

  /// Emit resolution for SOS
  void resolveSOS(String sosId, String outcome) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sos:resolve', {
        'sosId': sosId,
        'outcome': outcome,
      });
      print('📤 Sent SOS resolution: $sosId');
    }
  }

  /// Disconnect from Socket.IO
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _isConnected = false;
      _connectionController.add(false);
      print('🔌 Socket.IO disconnected');
    }
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
    _sosAlertsController.close();
    _connectionController.close();
  }
}
