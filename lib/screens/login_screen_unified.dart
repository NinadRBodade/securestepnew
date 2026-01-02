import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../config/api_config.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'agent/agent_home_screen.dart';
import 'resident/resident_home_screen.dart';
import 'guard/guard_home_screen.dart';

class LoginScreenUnified extends StatefulWidget {
  final String? userType;
  
  const LoginScreenUnified({super.key, this.userType});

  @override
  State<LoginScreenUnified> createState() => _LoginScreenUnifiedState();
}

class _LoginScreenUnifiedState extends State<LoginScreenUnified> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔄 Attempting login to: ${AppConstants.baseUrl}${AppConstants.authEndpoint}/login');
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': Validators.sanitizeEmail(_emailController.text),
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      print('📥 Login response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 && data['success'] == true) {
        // Save JWT token for API calls
        final token = data['token'];
        if (token != null) {
          ApiConfig.setToken(token);
          print('✅ JWT Token saved to ApiConfig: ${token.substring(0, 30)}...');
          print('✅ ApiConfig.token is now: ${ApiConfig.token.substring(0, 30)}...');
        } else {
          print('❌ WARNING: No token in response!');
        }
        
        // Successful login
        final userData = data['user'];
        final user = UserModel(
          id: userData['id'],
          email: userData['email'],
          role: userData['role'],
          name: userData['name'] ?? _getNameFromEmail(userData['email']),
          phone: userData['phone'] ?? userData['mobile'] ?? '',
          societyId: userData['societyId'] ?? '',
          flatNumber: userData['flatNumber'] ?? '',
          token: token,
        );
        
        // Save session for persistence
        await AuthService.saveSession(token: token, user: user);
        
        // Navigate to appropriate home screen based on role
        _navigateToHomeScreen(user);
      } else {
        _showError(data['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      // Fallback to mock authentication for offline testing
      print('❌ Login failed: $e');
      _showError('Backend unavailable: $e. Using mock login.');
      _mockLogin();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mockLogin() {
    print('⚠️⚠️⚠️ USING MOCK LOGIN - NO TOKEN WILL BE AVAILABLE ⚠️⚠️⚠️');
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    
    // Check mock credentials
    if (AppConstants.mockCredentials.containsKey(email) &&
        AppConstants.mockCredentials[email] == password) {
      
      // Determine role from email
      String role = AppConstants.roleResident;
      if (email.contains('agent')) {
        role = AppConstants.roleAgent;
      } else if (email.contains('guard')) {
        role = AppConstants.roleGuard;
      }
      
      final user = UserModel(
        email: email,
        role: role,
        name: _getNameFromEmail(email),
        phone: '',
        societyId: 'SOC${email.hashCode.abs() % 1000}',
        flatNumber: 'A-${email.hashCode.abs() % 500 + 100}',
      );
      
      _navigateToHomeScreen(user);
    } else {
      _showError('Invalid email or password');
    }
  }

  String _getNameFromEmail(String email) {
    return email.split('@')[0].toUpperCase();
  }

  void _navigateToHomeScreen(UserModel user) {
    Widget homeScreen;
    
    // Debug: Print the user role
    print('🔍 User role from backend: "${user.role}"');
    print('🔍 Expected agent role: "${AppConstants.roleAgent}"');
    
    switch (user.role.toLowerCase().trim()) {
      case 'agent':
        homeScreen = AgentHomeScreen(user: user);
        print('✅ Navigating to Agent Home Screen');
        break;
      case 'resident':
        homeScreen = ResidentHomeScreen(user: user);
        print('✅ Navigating to Resident Home Screen');
        break;
      case 'guard':
        homeScreen = GuardHomeScreen(user: user);
        print('✅ Navigating to Guard Home Screen');
        break;
      default:
        print('⚠️ Unknown role: "${user.role}" - defaulting to Resident');
        homeScreen = ResidentHomeScreen(user: user);
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => homeScreen),
    );
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
                    decoration: InputDecoration(
                      hintText: 'john@example.com',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                
                // Options Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember me
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
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
                    
                    // Forgot password
                    TextButton(
                      onPressed: () {
                        // Handle forgot password
                      },
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
                              builder: (context) => RegisterScreen(userType: widget.userType ?? 'independent'),
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
