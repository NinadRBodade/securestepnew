// SOS Event Model - Emergency alert data structure
import 'package:flutter/material.dart';

class SOSEvent {
  final String id;
  final String userId; // Who triggered the SOS
  final String userName;
  final String userRole; // resident, agent, guard
  final String? flatNumber; // For residents
  final DateTime timestamp;
  final String? latitude;
  final String? longitude;
  final String? locationAddress;
  final String status; // active, acknowledged, resolved, false_alarm
  final String? agentId; // If SOS triggered while agent present
  final String? agentName;
  final String? agentCompany;
  final String? description;
  final String? photoPath; // Local path to captured photo
  final String? guardId; // Guard who responded
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final bool isSynced; // Synced to server
  final String? blockchainHash; // For future blockchain integration
  
  SOSEvent({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.flatNumber,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.status = 'active',
    this.agentId,
    this.agentName,
    this.agentCompany,
    this.description,
    this.photoPath,
    this.guardId,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.isSynced = false,
    this.blockchainHash,
  });
  
  // Convert to JSON for storage/API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'flatNumber': flatNumber,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'status': status,
      'agentId': agentId,
      'agentName': agentName,
      'agentCompany': agentCompany,
      'description': description,
      'photoPath': photoPath,
      'guardId': guardId,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'isSynced': isSynced,
      'blockchainHash': blockchainHash,
    };
  }
  
  // Create from JSON
  factory SOSEvent.fromJson(Map<String, dynamic> json) {
    return SOSEvent(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userRole: json['userRole'],
      flatNumber: json['flatNumber'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      locationAddress: json['locationAddress'],
      status: json['status'] ?? 'active',
      agentId: json['agentId'],
      agentName: json['agentName'],
      agentCompany: json['agentCompany'],
      description: json['description'],
      photoPath: json['photoPath'],
      guardId: json['guardId'],
      acknowledgedAt: json['acknowledgedAt'] != null 
          ? DateTime.parse(json['acknowledgedAt']) 
          : null,
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.parse(json['resolvedAt']) 
          : null,
      resolutionNotes: json['resolutionNotes'],
      isSynced: json['isSynced'] ?? false,
      blockchainHash: json['blockchainHash'],
    );
  }
  
  // Copy with updated fields
  SOSEvent copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userRole,
    String? flatNumber,
    DateTime? timestamp,
    String? latitude,
    String? longitude,
    String? locationAddress,
    String? status,
    String? agentId,
    String? agentName,
    String? agentCompany,
    String? description,
    String? photoPath,
    String? guardId,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
    bool? isSynced,
    String? blockchainHash,
  }) {
    return SOSEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      flatNumber: flatNumber ?? this.flatNumber,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      status: status ?? this.status,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      agentCompany: agentCompany ?? this.agentCompany,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      guardId: guardId ?? this.guardId,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      isSynced: isSynced ?? this.isSynced,
      blockchainHash: blockchainHash ?? this.blockchainHash,
    );
  }
  
  // Get color based on status
  Color getStatusColor() {
    switch (status) {
      case 'active':
        return Colors.red;
      case 'acknowledged':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'false_alarm':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }
  
  // Get status display text
  String getStatusText() {
    switch (status) {
      case 'active':
        return 'ACTIVE EMERGENCY';
      case 'acknowledged':
        return 'Help On The Way';
      case 'resolved':
        return 'Resolved';
      case 'false_alarm':
        return 'False Alarm';
      default:
        return 'Unknown';
    }
  }
}
