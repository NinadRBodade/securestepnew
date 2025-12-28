import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

class ResidentEmergencyContactsScreen extends StatefulWidget {
  const ResidentEmergencyContactsScreen({super.key});

  @override
  State<ResidentEmergencyContactsScreen> createState() => _ResidentEmergencyContactsScreenState();
}

class _ResidentEmergencyContactsScreenState extends State<ResidentEmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.get('/residents/contacts');
      
      if (response.statusCode == 200 && response.data != null) {
        final status = response.data['status'];
        if (status == 'success') {
          if (mounted) {
            setState(() {
              final data = response.data['data'];
              if (data is List) {
                _contacts = List<Map<String, dynamic>>.from(data);
              } else {
                _contacts = [];
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Alphabets and spaces only',
                ),
                validator: (value) => Validators.validateName(value, fieldName: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: 'Relation',
                  prefixIcon: Icon(Icons.family_restroom),
                  hintText: 'Alphabets and spaces only',
                ),
                validator: (value) => Validators.validateName(value, fieldName: 'Relation'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Digits only',
                ),
                validator: (value) => Validators.validatePhone(value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
                  dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
                  
                  final response = await dio.post('/residents/contacts', data: {
                    'name': Validators.sanitizeName(nameController.text),
                    'relation': Validators.sanitizeName(relationController.text),
                    'phone': Validators.sanitizePhone(phoneController.text),
                  });
                  
                  if (response.statusCode == 201 && response.data != null && response.data['status'] == 'success') {
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  print('Add contact error: $e');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add contact. Please try again.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadContacts();
    }
  }

  Future<void> _deleteContact(String contactId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.delete('/residents/contacts/$contactId');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        _loadContacts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact deleted'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete contact: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No emergency contacts',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add contacts who should be notified in emergency',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Contact'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadContacts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              contact['name']?[0]?.toUpperCase() ?? '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          title: Text(
                            contact['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('👤 ${contact['relation'] ?? 'N/A'}'),
                              Text('📞 ${contact['phone'] ?? 'N/A'}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteContact(contact['_id'], contact['name']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
