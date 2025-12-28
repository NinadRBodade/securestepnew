import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import 'agent/agent_home_screen.dart';
import 'resident/resident_home_screen.dart';
import 'guard/guard_home_screen.dart';

// Login screen for selected role
class LoginScreen extends StatefulWidget {
  final String selectedRole;
  
  const LoginScreen({super.key, required this.selectedRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // To show/hide password
  bool _obscurePassword = true;
  
  // To show loading indicator
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Mock login function
  void _handleLogin() {
    // Get entered values
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    
    // Validation
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter email and password');
      return;
    }
    
    // Show loading
    setState(() {
      _isLoading = true;
    });
    
    // Simulate network delay
    Future.delayed(const Duration(seconds: 2), () {
      // Check mock credentials
      if (AppConstants.mockCredentials.containsKey(email) &&
          AppConstants.mockCredentials[email] == password) {
        
        // Create user model
        UserModel user = UserModel(
          email: email,
          role: widget.selectedRole,
          name: _getNameFromEmail(email),
        );
        
        // Navigate to appropriate home screen
        _navigateToHomeScreen(user);
        
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Invalid email or password');
      }
    });
  }
  
  // Extract name from email
  String _getNameFromEmail(String email) {
    return email.split('@')[0].toUpperCase();
  }
  
  // Navigate based on role
  void _navigateToHomeScreen(UserModel user) {
    Widget homeScreen;
    
    switch (widget.selectedRole) {
      case AppConstants.roleAgent:
        homeScreen = AgentHomeScreen(user: user);
        break;
      case AppConstants.roleResident:
        homeScreen = ResidentHomeScreen(user: user);
        break;
      case AppConstants.roleGuard:
        homeScreen = GuardHomeScreen(user: user);
        break;
      default:
        homeScreen = AgentHomeScreen(user: user);
    }
    
    // Replace current screen with home screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => homeScreen),
    );
  }
  
  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getRoleTitle()} Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Welcome text
              Text(
                'Welcome Back!',
                style: AppConstants.headingStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Login to continue as ${_getRoleTitle()}',
                style: AppConstants.subheadingStyle,
              ),
              const SizedBox(height: 40),
              
              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Login button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Login',
                      onPressed: _handleLogin,
                    ),
              const SizedBox(height: 20),
              
              // Demo credentials info
              _buildDemoCredentialsCard(),
            ],
          ),
        ),
      ),
    );
  }
  
  // Get role title
  String _getRoleTitle() {
    switch (widget.selectedRole) {
      case AppConstants.roleAgent:
        return 'Agent';
      case AppConstants.roleResident:
        return 'Resident';
      case AppConstants.roleGuard:
        return 'Guard';
      default:
        return 'User';
    }
  }
  
  // Demo credentials card
  Widget _buildDemoCredentialsCard() {
    String demoEmail = '';
    String demoPassword = '';
    
    switch (widget.selectedRole) {
      case AppConstants.roleAgent:
        demoEmail = 'agent@demo.com';
        demoPassword = 'agent123';
        break;
      case AppConstants.roleResident:
        demoEmail = 'resident@demo.com';
        demoPassword = 'resident123';
        break;
      case AppConstants.roleGuard:
        demoEmail = 'guard@demo.com';
        demoPassword = 'guard123';
        break;
    }
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Demo Credentials',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Email: $demoEmail'),
            Text('Password: $demoPassword'),
          ],
        ),
      ),
    );
  }
}