import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/phone_input_field.dart';
import 'resident_emergency_contacts_screen.dart';
import 'resident_settings_screen.dart';

class ResidentProfileScreen extends StatefulWidget {
  const ResidentProfileScreen({super.key});

  @override
  State<ResidentProfileScreen> createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _flatNumber = '';
  String _emergencyPreference = 'both';
  String _selectedCountryCode = '+91';
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.get('/residents/profile');
      
      if (response.statusCode == 200 && response.data != null) {
        final status = response.data['status'];
        if (status == 'success' && response.data['data'] != null) {
          final data = response.data['data'];
          if (mounted) {
            String phoneData = data['phone']?.toString() ?? '';
            // Extract country code if present
            if (phoneData.startsWith('+')) {
              final match = RegExp(r'^(\+\d{1,4})').firstMatch(phoneData);
              if (match != null) {
                _selectedCountryCode = match.group(1)!;
                phoneData = phoneData.substring(_selectedCountryCode.length);
              }
            }
            setState(() {
              _nameController.text = data['name']?.toString() ?? '';
              _phoneController.text = phoneData;
              _emailController.text = data['email']?.toString() ?? '';
              _flatNumber = data['flatNumber']?.toString() ?? '';
              _emergencyPreference = data['emergencyPreference']?.toString() ?? 'both';
            });
          }
        }
      }
    } catch (e) {
      print('Profile load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load profile. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.put('/residents/profile', data: {
        'name': Validators.sanitizeName(_nameController.text),
        'phone': _selectedCountryCode + Validators.sanitizePhone(_phoneController.text),
        'emergencyPreference': _emergencyPreference,
      });
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() => _isEditing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadProfile();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green,
                        child: Text(
                          _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: !_isEditing,
                        fillColor: _isEditing ? null : Colors.grey.shade100,
                        hintText: 'Alphabets and spaces only',
                      ),
                      validator: (value) => Validators.validateName(value, fieldName: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email field (read-only)
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone field
                    PhoneInputField(
                      controller: _phoneController,
                      label: 'Phone',
                      enabled: _isEditing,
                      onCountryCodeChanged: (code) {
                        setState(() => _selectedCountryCode = code);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Flat number (read-only)
                    TextFormField(
                      initialValue: _flatNumber,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Flat Number',
                        prefixIcon: const Icon(Icons.home),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Emergency preference
                    if (_isEditing) ...[
                      const Text('Emergency Alert Preference', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _emergencyPreference,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.notifications),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'push', child: Text('Push Only')),
                          DropdownMenuItem(value: 'sms', child: Text('SMS Only')),
                          DropdownMenuItem(value: 'both', child: Text('Both Push & SMS')),
                        ],
                        onChanged: (value) => setState(() => _emergencyPreference = value!),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Emergency Contacts Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResidentEmergencyContactsScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.contacts, color: Colors.purple, size: 28),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Emergency Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('Manage your emergency contacts', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
