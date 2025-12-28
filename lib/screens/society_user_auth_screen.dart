import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/phone_input_field.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'resident/resident_home_screen.dart';

/// Society User Login/Register Screen with society selector
class SocietyUserAuthScreen extends StatefulWidget {
  const SocietyUserAuthScreen({super.key});

  @override
  State<SocietyUserAuthScreen> createState() => _SocietyUserAuthScreenState();
}

class _SocietyUserAuthScreenState extends State<SocietyUserAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatNumberController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingSocieties = false;
  String _selectedCountryCode = '+91';
  
  String? _selectedSocietyId;
  String? _selectedSocietyName;
  List<Map<String, dynamic>> _societies = [];

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _flatNumberController.dispose();
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
            Expanded(
              child: _societies.isEmpty
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

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate society selection
    if (_selectedSocietyId == null) {
      _showError('Please select your society');
      return;
    }

    // Validate flat number for registration
    if (!_isLogin && _flatNumberController.text.trim().isEmpty) {
      _showError('Please enter your flat/house number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _handleLogin();
      } else {
        await _handleRegister();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': Validators.sanitizeEmail(_emailController.text),
        'password': _passwordController.text,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['token'];
      if (token != null) {
        ApiConfig.setToken(token);
      }

      final userData = data['user'];
      final user = UserModel(
        email: userData['email'],
        role: userData['role'],
        name: userData['name'],
        phone: userData['phone'],
        societyId: userData['societyId'],
        flatNumber: userData['flatNumber'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResidentHomeScreen(user: user),
          ),
        );
      }
    } else {
      _showError(data['message'] ?? 'Login failed');
    }
  }

  Future<void> _handleRegister() async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': Validators.sanitizeName(_nameController.text),
        'email': Validators.sanitizeEmail(_emailController.text),
        'password': _passwordController.text,
        'phone': _selectedCountryCode + Validators.sanitizePhone(_phoneController.text),
        'role': 'resident',
        'societyId': _selectedSocietyId,
        'flatNumber': _flatNumberController.text.trim(),
      }),
    ).timeout(const Duration(seconds: 10));

    final data = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isLogin = true);
      }
    } else {
      _showError(data['message'] ?? 'Registration failed');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                
                // App Icon with Gradient
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5B6CFF), Color(0xFF4DA1FF)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'Sign in to continue to Secure Step',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Society Label
                const Text(
                  'Society',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Society Selector
                InkWell(
                  onTap: _showSocietyPicker,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.apartment,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedSocietyName ?? 'Select Your Society',
                            style: TextStyle(
                              fontSize: 15,
                              color: _selectedSocietyName != null
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
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
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'john@example.com',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: Validators.validateEmail,
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
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Options Row (Remember me & Forgot Password)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: false,
                            onChanged: (value) {},
                            activeColor: const Color(0xFF5B6CFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4DA1FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Sign In Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF5B6CFF), Color(0xFF4DA1FF)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : () => _handleLogin(),
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
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign Up Section
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SocietyUserRegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4DA1FF),
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

/// Society User Registration Screen
class SocietyUserRegisterScreen extends StatefulWidget {
  const SocietyUserRegisterScreen({super.key});

  @override
  State<SocietyUserRegisterScreen> createState() => _SocietyUserRegisterScreenState();
}

class _SocietyUserRegisterScreenState extends State<SocietyUserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatNumberController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingSocieties = false;
  String _selectedCountryCode = '+91';
  
  String? _selectedSocietyId;
  String? _selectedSocietyName;
  List<Map<String, dynamic>> _societies = [];

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _flatNumberController.dispose();
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingSocieties
                  ? const Center(child: CircularProgressIndicator())
                  : _societies.isEmpty
                      ? const Center(child: Text('No societies available'))
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
                              subtitle: Text(society['city'] ?? ''),
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

    if (_selectedSocietyId == null) {
      _showError('Please select your society');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': Validators.sanitizeName(_nameController.text),
          'email': Validators.sanitizeEmail(_emailController.text),
          'password': _passwordController.text,
          'phone': _selectedCountryCode + Validators.sanitizePhone(_phoneController.text),
          'role': 'resident',
          'societyId': _selectedSocietyId,
          'flatNumber': _flatNumberController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _showError(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
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
                  'Register',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'Create your account to get started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Society Selector
                InkWell(
                  onTap: _showSocietyPicker,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.apartment,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedSocietyName ?? 'Select Your Society *',
                            style: TextStyle(
                              fontSize: 15,
                              color: _selectedSocietyName != null
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Full Name Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      hintStyle: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFF6B7280), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) => Validators.validateName(value),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF6B7280), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: Validators.validateEmail,
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Field
                PhoneInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  onCountryCodeChanged: (code) {
                    setState(() => _selectedCountryCode = code);
                  },
                ),
                const SizedBox(height: 16),

                // Flat Number Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: TextFormField(
                    controller: _flatNumberController,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Flat/House Number *',
                      hintStyle: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                      prefixIcon: Icon(Icons.home_outlined, color: Color(0xFF6B7280), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter flat/house number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF6B7280),
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
                const SizedBox(height: 24),

                // Register Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
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
                const SizedBox(height: 24),

                // Login Link
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
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
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
