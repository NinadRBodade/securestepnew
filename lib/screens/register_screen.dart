import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/phone_input_field.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'login_screen_unified.dart';
import 'agent/agent_home_screen.dart';
import 'resident/resident_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? userType;
  
  const RegisterScreen({super.key, this.userType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _societyController = TextEditingController();
  final _flatNumberController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedRole = AppConstants.roleResident;
  String _selectedCountryCode = '+91';
  String _residentType = ''; // 'independent' or 'society'
  String? _selectedSocietyId;
  String? _selectedSocietyName;
  List<Map<String, dynamic>> _societies = [];
  bool _isLoadingSocieties = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-set values based on userType from navigation
    if (widget.userType == 'independent') {
      _selectedRole = AppConstants.roleResident;
      _residentType = 'independent';
    } else if (widget.userType == 'agent') {
      _selectedRole = AppConstants.roleAgent;
    }
    // Guards cannot register via mobile app - removed guard option
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _societyController.dispose();
    _flatNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchSocieties() async {
    setState(() => _isLoadingSocieties = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/society/list'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['societies'] != null) {
          setState(() {
            _societies = List<Map<String, dynamic>>.from(data['societies']);
          });
        }
      }
    } catch (e) {
      print('Error fetching societies: $e');
      _showError('Could not load societies. Please try again.');
    } finally {
      setState(() => _isLoadingSocieties = false);
    }
  }

  void _showSocietyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Your Society',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search society...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  // Filter societies based on search
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingSocieties
                  ? const Center(child: CircularProgressIndicator())
                  : _societies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apartment, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No societies available',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _societies.length,
                          itemBuilder: (context, index) {
                            final society = _societies[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.apartment),
                              ),
                              title: Text(society['name'] ?? ''),
                              subtitle: society['city'] != null
                                  ? Text(society['city'])
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedSocietyId = society['_id'];
                                  _selectedSocietyName = society['name'];
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate resident type selection
    if (_selectedRole == AppConstants.roleResident && _residentType.isEmpty) {
      _showError('Please select if you live in a society or independent house');
      return;
    }

    // Validate society selection for society residents
    if (_selectedRole == AppConstants.roleResident && 
        _residentType == 'society' && 
        _selectedSocietyId == null) {
      _showError('Please select your society');
      return;
    }

    // Validate flat number for society residents
    if (_selectedRole == AppConstants.roleResident && 
        _residentType == 'society' && 
        _flatNumberController.text.trim().isEmpty) {
      _showError('Please enter your flat/house number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> registrationData = {
        'name': Validators.sanitizeName(_nameController.text),
        'email': Validators.sanitizeEmail(_emailController.text),
        'password': _passwordController.text,
        'phone': _selectedCountryCode + Validators.sanitizePhone(_phoneController.text),
        'role': _selectedRole,
      };

      // Add society-specific data only for residents
      if (_selectedRole == AppConstants.roleResident) {
        if (_residentType == 'society') {
          registrationData['societyId'] = _selectedSocietyId;
          registrationData['flatNumber'] = _flatNumberController.text.trim();
        }
        // Independent house residents don't need societyId/flatNumber
      } else if (_selectedRole == AppConstants.roleAgent) {
        // Add address for agents
        if (_addressController.text.trim().isNotEmpty) {
          registrationData['address'] = _addressController.text.trim();
        }
      }
      // Guards should NOT register via mobile app - they are created by admin
      // So no guard-specific data needed here

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registrationData),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful - always redirect to login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login with your credentials.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreenUnified(userType: widget.userType)),
          );
        }
      } else {
        // Show detailed validation errors
        String errorMessage = data['message'] ?? 'Registration failed';
        if (data['errors'] != null && data['errors'] is List && data['errors'].isNotEmpty) {
          errorMessage = data['errors'].join('\n');
        }
        _showError(errorMessage);
      }
    } catch (e) {
      print('Registration error: $e');
      _showError('Connection error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine title based on userType
    String title = 'Create Account';
    if (widget.userType == 'independent') {
      title = 'Independent House Registration';
      return _buildIndependentHouseUI(context);
    } else if (widget.userType == 'agent') {
      title = 'Agent Registration';
      return _buildAgentUI(context);
    } else if (widget.userType == 'guard') {
      title = 'Guard Registration';
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Register',
                  style: AppConstants.headingStyle,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your account to get started',
                  style: AppConstants.subheadingStyle,
                ),
                const SizedBox(height: 30),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    hintText: 'Alphabets and spaces only',
                  ),
                  validator: (value) => Validators.validateName(value, fieldName: 'Name'),
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                    hintText: 'your.email@example.com',
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                // Phone field with country code
                PhoneInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  onCountryCodeChanged: (code) {
                    setState(() => _selectedCountryCode = code);
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    hintText: 'Min 8 chars, 1 upper, 1 lower, 1 number',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),

                // Role selection (only show if not coming from role selection flow)
                if (widget.userType == null)
                  DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Select Role',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AppConstants.roleResident,
                      child: Text('Resident'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.roleAgent,
                      child: Text('Agent / Delivery Person'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      // Reset resident-specific fields when role changes
                      if (_selectedRole != AppConstants.roleResident) {
                        _residentType = '';
                        _selectedSocietyId = null;
                        _selectedSocietyName = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Resident type selection (only for residents and NOT when already selected from user flow)
                if (_selectedRole == AppConstants.roleResident && widget.userType == null) ...[
                  const Text(
                    'Do you live in a society?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Resident type buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _residentType = 'independent';
                              _selectedSocietyId = null;
                              _selectedSocietyName = null;
                            });
                          },
                          icon: Icon(
                            Icons.house,
                            color: _residentType == 'independent'
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                          ),
                          label: const Text('Independent\nHouse'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _residentType == 'independent'
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                            foregroundColor: _residentType == 'independent'
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _residentType = 'society';
                            });
                            _fetchSocieties();
                          },
                          icon: Icon(
                            Icons.apartment,
                            color: _residentType == 'society'
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                          ),
                          label: const Text('Society\nResident'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _residentType == 'society'
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                            foregroundColor: _residentType == 'society'
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Society selection (only for society residents)
                  if (_residentType == 'society') ...[
                    InkWell(
                      onTap: () {
                        if (_societies.isEmpty) {
                          _fetchSocieties();
                        }
                        _showSocietyPicker();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.apartment, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedSocietyName ?? 'Select Your Society',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedSocietyName != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Flat number (required for society residents)
                    TextFormField(
                      controller: _flatNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Flat/House Number *',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                        hintText: 'e.g., A-101',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // Society fields for other roles (optional)
                if (_selectedRole != AppConstants.roleResident) ...[
                  TextFormField(
                    controller: _societyController,
                    decoration: const InputDecoration(
                      labelText: 'Society Name (Optional)',
                      prefixIcon: Icon(Icons.apartment),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Green Valley Apartments',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _flatNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Flat/House Number (Optional)',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., A-101',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const SizedBox(height: 14),

                // Register button
                CustomButton(
                  text: _isLoading ? 'Creating Account...' : 'Register',
                  onPressed: _isLoading ? () {} : () => _handleRegister(),
                ),
                const SizedBox(height: 20),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreenUnified(userType: widget.userType),
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New UI for Independent House Registration
  Widget _buildIndependentHouseUI(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 24),
                
                // Header
                const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Phone Number Field
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Password Field
                _buildPasswordField(),
                const SizedBox(height: 32),

                // Register Button
                _buildGradientButton(context),
                const SizedBox(height: 24),

                // Footer Text
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreenUnified(userType: 'independent'),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: Colors.grey[700],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        onTap: () {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            size: 20,
            color: Colors.grey[700],
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildGradientButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : () => _handleRegister(),
            borderRadius: BorderRadius.circular(28),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Agent Registration UI
  Widget _buildAgentUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Agent Register',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'Create your agent account to get started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Full Name Label
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Full Name Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'John Doe',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) => Validators.validateName(value),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Label
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),

                // Email Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'agent@example.com',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: Validators.validateEmail,
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Number Label
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),

                // Phone Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: '+1 234 567 8900',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Password Label
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),

                // Password Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9CA3AF),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: Validators.validatePassword,
                  ),
                ),
                const SizedBox(height: 16),

                // Address Label
                const Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),

                // Address Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _addressController,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: '123 Main Street',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Register Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3310B981),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : () => _handleRegister(),
                      borderRadius: BorderRadius.circular(30),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Footer Text
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreenUnified(userType: widget.userType),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
