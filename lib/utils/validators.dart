/// Input validation utilities for form fields
class Validators {
  // Phone number validation
  static String? validatePhone(String? value, {String countryCode = '+91'}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all whitespace and special characters
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanedValue)) {
      return 'Phone number must contain only digits';
    }

    // Validate length based on country code
    final int expectedLength = _getPhoneLengthForCountry(countryCode);
    if (cleanedValue.length != expectedLength) {
      return 'Phone number must be exactly $expectedLength digits';
    }

    return null;
  }

  // Get expected phone length for country code
  static int _getPhoneLengthForCountry(String countryCode) {
    switch (countryCode) {
      case '+91': // India
        return 10;
      case '+1': // USA/Canada
        return 10;
      case '+44': // UK
        return 10;
      case '+86': // China
        return 11;
      case '+81': // Japan
        return 10;
      case '+61': // Australia
        return 9;
      case '+971': // UAE
        return 9;
      default:
        return 10; // Default length
    }
  }

  // Name validation (alphabets and spaces only)
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $fieldName';
    }

    final trimmedValue = value.trim();

    // Check if contains only alphabets and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmedValue)) {
      return '$fieldName must contain only alphabets and spaces';
    }

    // Check minimum length (at least 2 characters)
    if (trimmedValue.length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    // Check if not all spaces
    if (trimmedValue.replaceAll(' ', '').isEmpty) {
      return 'Please enter a valid $fieldName';
    }

    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final trimmedValue = value.trim().toLowerCase();

    // RFC 5322 compliant email regex (simplified)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    // Minimum 8 characters
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // At least 1 uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least 1 uppercase letter';
    }

    // At least 1 lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least 1 lowercase letter';
    }

    // At least 1 number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least 1 number';
    }

    return null;
  }

  // Sanitize email (trim and lowercase)
  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // Sanitize phone (remove all non-digit characters)
  static String sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Sanitize name (trim and remove extra spaces)
  static String sanitizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Get list of supported country codes
  static List<Map<String, String>> getCountryCodes() {
    return [
      {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
      {'code': '+1', 'country': 'USA/Canada', 'flag': '🇺🇸'},
      {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
      {'code': '+86', 'country': 'China', 'flag': '🇨🇳'},
      {'code': '+81', 'country': 'Japan', 'flag': '🇯🇵'},
      {'code': '+61', 'country': 'Australia', 'flag': '🇦🇺'},
      {'code': '+971', 'country': 'UAE', 'flag': '🇦🇪'},
      {'code': '+49', 'country': 'Germany', 'flag': '🇩🇪'},
      {'code': '+33', 'country': 'France', 'flag': '🇫🇷'},
      {'code': '+65', 'country': 'Singapore', 'flag': '🇸🇬'},
    ];
  }

  // Format phone for display
  static String formatPhoneForDisplay(String phone, String countryCode) {
    final cleaned = sanitizePhone(phone);
    if (countryCode == '+91' && cleaned.length == 10) {
      return '${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    return cleaned;
  }
}
