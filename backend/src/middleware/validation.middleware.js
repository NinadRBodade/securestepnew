/**
 * Validation middleware for request data
 */

// Phone validation with country code support
const validatePhone = (phone, countryCode = '+91') => {
  if (!phone) {
    return { valid: false, message: 'Phone number is required' };
  }

  // Convert to string and remove all non-digit characters
  let phoneNumber = phone.toString().replace(/\D/g, '');

  // If phone is empty after removing non-digits
  if (!phoneNumber) {
    return { valid: false, message: 'Phone number must contain digits' };
  }

  // Validate length based on country code
  const expectedLength = getPhoneLengthForCountry(countryCode);
  if (phoneNumber.length !== expectedLength) {
    return { 
      valid: false, 
      message: `Phone number must be exactly ${expectedLength} digits` 
    };
  }

  return { valid: true, sanitized: phoneNumber };
};

// Get expected phone length for country code
const getPhoneLengthForCountry = (countryCode) => {
  const lengths = {
    '+91': 10,  // India
    '+1': 10,   // USA/Canada
    '+44': 10,  // UK
    '+86': 11,  // China
    '+81': 10,  // Japan
    '+61': 9,   // Australia
    '+971': 9,  // UAE
  };
  return lengths[countryCode] || 10;
};

// Name validation (alphabets and spaces only)
const validateName = (name, fieldName = 'Name') => {
  if (!name) {
    return { valid: false, message: `${fieldName} is required` };
  }

  const trimmedName = name.toString().trim();

  // Check if contains only alphabets and spaces
  if (!/^[a-zA-Z\s]+$/.test(trimmedName)) {
    return { 
      valid: false, 
      message: `${fieldName} must contain only alphabets and spaces` 
    };
  }

  // Check minimum length
  if (trimmedName.length < 2) {
    return { 
      valid: false, 
      message: `${fieldName} must be at least 2 characters` 
    };
  }

  // Check if not all spaces
  if (trimmedName.replace(/\s/g, '').length === 0) {
    return { valid: false, message: `Please enter a valid ${fieldName}` };
  }

  return { valid: true, sanitized: trimmedName.replace(/\s+/g, ' ') };
};

// Email validation
const validateEmail = (email) => {
  if (!email) {
    return { valid: false, message: 'Email is required' };
  }

  const trimmedEmail = email.toString().trim().toLowerCase();

  // RFC 5322 compliant email regex (simplified)
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

  if (!emailRegex.test(trimmedEmail)) {
    return { valid: false, message: 'Please enter a valid email address' };
  }

  return { valid: true, sanitized: trimmedEmail };
};

// Password validation
const validatePassword = (password) => {
  if (!password) {
    return { valid: false, message: 'Password is required' };
  }

  const pwd = password.toString();

  // Minimum 8 characters
  if (pwd.length < 8) {
    return { valid: false, message: 'Password must be at least 8 characters' };
  }

  // At least 1 uppercase letter
  if (!/[A-Z]/.test(pwd)) {
    return { 
      valid: false, 
      message: 'Password must contain at least 1 uppercase letter' 
    };
  }

  // At least 1 lowercase letter
  if (!/[a-z]/.test(pwd)) {
    return { 
      valid: false, 
      message: 'Password must contain at least 1 lowercase letter' 
    };
  }

  // At least 1 number
  if (!/[0-9]/.test(pwd)) {
    return { valid: false, message: 'Password must contain at least 1 number' };
  }

  return { valid: true };
};

// Sanitize functions
const sanitizeEmail = (email) => {
  return email ? email.toString().trim().toLowerCase() : '';
};

const sanitizePhone = (phone) => {
  return phone ? phone.toString().replace(/\D/g, '') : '';
};

const sanitizeName = (name) => {
  return name ? name.toString().trim().replace(/\s+/g, ' ') : '';
};

// Validation middleware for registration
const validateRegistration = (req, res, next) => {
  const { name, email, password, phone } = req.body;
  const errors = [];

  // Validate name
  const nameValidation = validateName(name, 'Name');
  if (!nameValidation.valid) {
    errors.push(nameValidation.message);
  } else {
    req.body.name = nameValidation.sanitized;
  }

  // Validate email
  const emailValidation = validateEmail(email);
  if (!emailValidation.valid) {
    errors.push(emailValidation.message);
  } else {
    req.body.email = emailValidation.sanitized;
  }

  // Validate password
  const passwordValidation = validatePassword(password);
  if (!passwordValidation.valid) {
    errors.push(passwordValidation.message);
  }

  // Validate phone - simplified, no strict validation
  if (phone) {
    let phoneStr = phone.toString().trim();
    
    // Extract all digits
    let cleanPhone = phoneStr.replace(/\D/g, '');
    
    // Basic validation - must have at least 10 digits
    if (cleanPhone.length < 10) {
      errors.push('Phone number must have at least 10 digits');
    } else {
      // Take last 10 digits if more than 10 (handles country codes)
      if (cleanPhone.length > 10) {
        cleanPhone = cleanPhone.slice(-10);
      }
      // Store with +91 prefix
      req.body.phone = '+91' + cleanPhone;
      req.body.mobile = '+91' + cleanPhone;
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors
    });
  }

  next();
};

// Validation middleware for login
const validateLogin = (req, res, next) => {
  const { email, phone, password } = req.body;
  const errors = [];

  // Must have either email or phone
  if (!email && !phone) {
    errors.push('Email or phone number is required');
  }

  // Validate email if provided
  if (email) {
    const emailValidation = validateEmail(email);
    if (!emailValidation.valid) {
      errors.push(emailValidation.message);
    } else {
      req.body.email = emailValidation.sanitized;
    }
  }

  // Validate phone if provided
  if (phone) {
    let countryCode = '+91';
    let phoneNumber = phone.toString();
    
    if (phoneNumber.startsWith('+')) {
      const match = phoneNumber.match(/^(\+\d{1,4})(.+)$/);
      if (match) {
        countryCode = match[1];
        phoneNumber = match[2];
      }
    }

    const phoneValidation = validatePhone(phoneNumber, countryCode);
    if (!phoneValidation.valid) {
      errors.push(phoneValidation.message);
    } else {
      req.body.phone = countryCode + phoneValidation.sanitized;
    }
  }

  // Check password is present
  if (!password || password.toString().trim().length === 0) {
    errors.push('Password is required');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors
    });
  }

  next();
};

// Validation middleware for profile update
const validateProfileUpdate = (req, res, next) => {
  const { name, phone } = req.body;
  const errors = [];

  // Validate name if provided
  if (name) {
    const nameValidation = validateName(name, 'Name');
    if (!nameValidation.valid) {
      errors.push(nameValidation.message);
    } else {
      req.body.name = nameValidation.sanitized;
    }
  }

  // Validate phone if provided
  if (phone) {
    let countryCode = '+91';
    let phoneNumber = phone.toString();
    
    if (phoneNumber.startsWith('+')) {
      const match = phoneNumber.match(/^(\+\d{1,4})(.+)$/);
      if (match) {
        countryCode = match[1];
        phoneNumber = match[2];
      }
    }

    const phoneValidation = validatePhone(phoneNumber, countryCode);
    if (!phoneValidation.valid) {
      errors.push(phoneValidation.message);
    } else {
      req.body.phone = countryCode + phoneValidation.sanitized;
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors
    });
  }

  next();
};

// Validation middleware for emergency contact
const validateEmergencyContact = (req, res, next) => {
  const { name, relation, phone } = req.body;
  const errors = [];

  // Validate name
  const nameValidation = validateName(name, 'Name');
  if (!nameValidation.valid) {
    errors.push(nameValidation.message);
  } else {
    req.body.name = nameValidation.sanitized;
  }

  // Validate relation
  if (relation) {
    const relationValidation = validateName(relation, 'Relation');
    if (!relationValidation.valid) {
      errors.push(relationValidation.message);
    } else {
      req.body.relation = relationValidation.sanitized;
    }
  }

  // Validate phone
  if (phone) {
    let countryCode = '+91';
    let phoneNumber = phone.toString();
    
    if (phoneNumber.startsWith('+')) {
      const match = phoneNumber.match(/^(\+\d{1,4})(.+)$/);
      if (match) {
        countryCode = match[1];
        phoneNumber = match[2];
      }
    }

    const phoneValidation = validatePhone(phoneNumber, countryCode);
    if (!phoneValidation.valid) {
      errors.push(phoneValidation.message);
    } else {
      req.body.phone = countryCode + phoneValidation.sanitized;
    }
  }

  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors
    });
  }

  next();
};

module.exports = {
  validatePhone,
  validateName,
  validateEmail,
  validatePassword,
  sanitizeEmail,
  sanitizePhone,
  sanitizeName,
  validateRegistration,
  validateLogin,
  validateProfileUpdate,
  validateEmergencyContact
};
