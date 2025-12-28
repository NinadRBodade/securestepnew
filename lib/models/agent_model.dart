// Agent model with verification details
class AgentModel {
  final String id;
  final String name;
  final String email;
  final String company;
  final String phone;
  final String documentId; // Aadhaar/ID number (mock)
  final String photo; // URL or base64 (using asset path for demo)
  final bool isVerified;
  final int safetyScore;
  final DateTime joinedDate;
  
  AgentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
    required this.phone,
    required this.documentId,
    required this.photo,
    this.isVerified = false,
    this.safetyScore = 100,
    required this.joinedDate,
  });
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'company': company,
      'phone': phone,
      'documentId': documentId,
      'photo': photo,
      'isVerified': isVerified,
      'safetyScore': safetyScore,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }
  
  // Create from JSON
  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      company: json['company'],
      phone: json['phone'],
      documentId: json['documentId'],
      photo: json['photo'],
      isVerified: json['isVerified'] ?? false,
      safetyScore: json['safetyScore'] ?? 100,
      joinedDate: DateTime.parse(json['joinedDate']),
    );
  }
  
  // Convert to Map (for passing to screens)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'company': company,
      'phone': phone,
      'documentId': documentId,
      'photo': photo,
      'isVerified': isVerified,
      'safetyScore': safetyScore,
      'purpose': 'Delivery', // Default purpose for display
    };
  }
  
  // Copy with method for updating fields
  AgentModel copyWith({
    String? id,
    String? name,
    String? email,
    String? company,
    String? phone,
    String? documentId,
    String? photo,
    bool? isVerified,
    int? safetyScore,
    DateTime? joinedDate,
  }) {
    return AgentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      documentId: documentId ?? this.documentId,
      photo: photo ?? this.photo,
      isVerified: isVerified ?? this.isVerified,
      safetyScore: safetyScore ?? this.safetyScore,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }
}