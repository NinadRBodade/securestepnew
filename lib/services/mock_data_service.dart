import '../models/agent_model.dart';
import '../models/user_model.dart';

// Mock data service for demo purposes
class MockDataService {
  // Singleton pattern
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();
  
  // Mock agents list
  final List<AgentModel> _agents = [
    AgentModel(
      id: 'AGT001',
      name: 'Rajesh Kumar',
      email: 'agent@demo.com',
      company: 'Swiggy',
      phone: '+91 98765 43210',
      documentId: 'XXXX-XXXX-1234',
      photo: 'assets/agent_photo.png', // We'll use placeholder
      isVerified: true,
      safetyScore: 95,
      joinedDate: DateTime(2024, 1, 15),
    ),
    AgentModel(
      id: 'AGT002',
      name: 'Priya Sharma',
      email: 'priya@demo.com',
      company: 'Zomato',
      phone: '+91 87654 32109',
      documentId: 'XXXX-XXXX-5678',
      photo: 'assets/agent_photo.png',
      isVerified: true,
      safetyScore: 98,
      joinedDate: DateTime(2024, 2, 10),
    ),
    AgentModel(
      id: 'AGT003',
      name: 'Amit Patel',
      email: 'amit@demo.com',
      company: 'Amazon',
      phone: '+91 76543 21098',
      documentId: 'XXXX-XXXX-9012',
      photo: 'assets/agent_photo.png',
      isVerified: false, // Pending verification
      safetyScore: 100,
      joinedDate: DateTime(2024, 12, 1),
    ),
  ];
  
  // Get all agents
  List<AgentModel> getAllAgents() {
    return _agents;
  }
  
  // Get agent by ID
  AgentModel? getAgentById(String id) {
    try {
      return _agents.firstWhere((agent) => agent.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get agent by email
  AgentModel? getAgentByEmail(String email) {
    try {
      return _agents.firstWhere((agent) => agent.email == email);
    } catch (e) {
      return null;
    }
  }
  
  // Get verified agents only
  List<AgentModel> getVerifiedAgents() {
    return _agents.where((agent) => agent.isVerified).toList();
  }
  
  // Get unverified agents
  List<AgentModel> getUnverifiedAgents() {
    return _agents.where((agent) => !agent.isVerified).toList();
  }
  
  // Verify agent
  void verifyAgent(String id) {
    final index = _agents.indexWhere((agent) => agent.id == id);
    if (index != -1) {
      _agents[index] = _agents[index].copyWith(isVerified: true);
    }
  }
  
  // Reject agent
  void rejectAgent(String id) {
    final index = _agents.indexWhere((agent) => agent.id == id);
    if (index != -1) {
      _agents[index] = _agents[index].copyWith(isVerified: false);
    }
  }
  
  // Get all residents
  static List<UserModel> getResidents() {
    // Return mock residents data
    return [
      UserModel(email: 'resident@demo.com', role: 'resident', name: 'Ramesh Singh', phone: '', societyId: '', flatNumber: ''),
      UserModel(email: 'resident2@demo.com', role: 'resident', name: 'Priya Verma', phone: '', societyId: '', flatNumber: ''),
      UserModel(email: 'resident3@demo.com', role: 'resident', name: 'Arjun Mehta', phone: '', societyId: '', flatNumber: ''),
    ];
  }
  
  // Update safety score
  void updateSafetyScore(String id, int newScore) {
    final index = _agents.indexWhere((agent) => agent.id == id);
    if (index != -1) {
      _agents[index] = _agents[index].copyWith(safetyScore: newScore);
    }
  }
}