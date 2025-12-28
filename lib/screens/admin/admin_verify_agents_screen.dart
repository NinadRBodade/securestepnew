import 'package:flutter/material.dart';
import '../../models/agent_model.dart';
import '../../services/mock_data_service.dart';
import '../../utils/constants.dart';

// Admin screen to verify/reject agents
class AdminVerifyAgentsScreen extends StatefulWidget {
  const AdminVerifyAgentsScreen({super.key});

  @override
  State<AdminVerifyAgentsScreen> createState() => _AdminVerifyAgentsScreenState();
}

class _AdminVerifyAgentsScreenState extends State<AdminVerifyAgentsScreen> {
  final MockDataService _dataService = MockDataService();
  List<AgentModel> _pendingAgents = [];
  List<AgentModel> _verifiedAgents = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0 = Pending, 1 = Verified

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  void _loadAgents() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _pendingAgents = _dataService.getUnverifiedAgents();
        _verifiedAgents = _dataService.getVerifiedAgents();
        _isLoading = false;
      });
    });
  }

  void _verifyAgent(AgentModel agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Agent'),
        content: Text('Are you sure you want to verify ${agent.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _dataService.verifyAgent(agent.id);
              Navigator.pop(context);
              _loadAgents();
              _showSnackBar('${agent.name} has been verified', Colors.green);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _rejectAgent(AgentModel agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Agent'),
        content: Text('Are you sure you want to reject ${agent.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _dataService.rejectAgent(agent.id);
              Navigator.pop(context);
              _loadAgents();
              _showSnackBar('${agent.name} has been rejected', Colors.red);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Agents'),
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),
          
          // Agent list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAgentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Pending',
              _pendingAgents.length,
              0,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton(
              'Verified',
              _verifiedAgents.length,
              1,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int count, int index, Color color) {
    final isSelected = _selectedTab == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentList() {
    final agents = _selectedTab == 0 ? _pendingAgents : _verifiedAgents;
    
    if (agents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 0 ? Icons.check_circle : Icons.person,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTab == 0
                  ? 'No pending verifications'
                  : 'No verified agents yet',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        return _buildAgentCard(agents[index]);
      },
    );
  }

  Widget _buildAgentCard(AgentModel agent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                  child: Text(
                    agent.name[0],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            agent.company,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: agent.isVerified ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    agent.isVerified ? 'Verified' : 'Pending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Agent details
            _buildInfoRow(Icons.email, agent.email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, agent.phone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.badge, 'ID: ${agent.documentId}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.star, 'Safety Score: ${agent.safetyScore}/100'),
            
            // Action buttons (only for pending)
            if (!agent.isVerified) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectAgent(agent),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyAgent(agent),
                      icon: const Icon(Icons.check),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}