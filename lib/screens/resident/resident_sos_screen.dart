import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sos_event_model.dart';
import '../../services/sos_service.dart';

class ResidentSOSScreen extends StatefulWidget {
  final UserModel user;
  
  const ResidentSOSScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ResidentSOSScreen> createState() => _ResidentSOSScreenState();
}

class _ResidentSOSScreenState extends State<ResidentSOSScreen> {
  final SOSService _sosService = SOSService();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _selectedEmergencyType;
  
  final List<Map<String, dynamic>> _emergencyTypes = [
    {'type': 'Suspicious Person', 'icon': Icons.person_search, 'color': Colors.orange},
    {'type': 'Medical Emergency', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'type': 'Fire', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'type': 'Theft', 'icon': Icons.report_problem, 'color': Colors.purple},
    {'type': 'Violence', 'icon': Icons.warning, 'color': Colors.red[900]},
    {'type': 'Other', 'icon': Icons.emergency, 'color': Colors.blueGrey},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    if (_selectedEmergencyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select emergency type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check location permission
      final hasPermission = await _sosService.checkLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission required for SOS'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Trigger SOS
      final description = '${_selectedEmergencyType ?? 'Emergency'}: ${_descriptionController.text.trim()}';
      
      final sosEvent = await _sosService.triggerSOS(
        societyId: widget.user.societyId ?? 'SOC${widget.user.email.hashCode.abs() % 1000}',
        flatNumber: widget.user.flatNumber ?? _getFlatNumber(widget.user.email),
        description: description,
        userId: widget.user.email,
        userName: widget.user.name,
      );
      
      if (mounted) {
        // Show success dialog
        _showSuccessDialog(sosEvent);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFlatNumber(String email) {
    // Generate flat number from email hash (A-100 to A-599)
    final hash = email.hashCode.abs();
    final flatNum = 100 + (hash % 500);
    return 'A-$flatNum';
  }

  void _showSuccessDialog(SOSEvent event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('SOS Alert Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your emergency alert has been sent.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow('Alert ID', event.id.substring(0, 8)),
            _buildInfoRow('Time', _formatTime(event.timestamp)),
            _buildInfoRow('Status', event.status.toUpperCase()),
            if (event.locationAddress != null)
              _buildInfoRow('Location', event.locationAddress!, maxLines: 2),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    'Guards and police have been notified.\nHelp is on the way.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Alert System',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Use only in case of genuine emergency',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Emergency type selection
            Text(
              'Select Emergency Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _emergencyTypes.length,
              itemBuilder: (context, index) {
                final type = _emergencyTypes[index];
                final isSelected = _selectedEmergencyType == type['type'];
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedEmergencyType = type['type'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? type['color'] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? type['color'] : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type['icon'],
                          color: isSelected ? Colors.white : type['color'],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          type['type'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 24),
            
            // Description field
            Text(
              'Additional Details (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Describe the emergency situation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Send SOS button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _triggerSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'SEND SOS ALERT',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Info text
            Center(
              child: Text(
                'This will alert guards and police with your location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}