/// Input validators for form fields
class Validators {
  Validators._(); // Private constructor

  // ============ TEXT VALIDATORS ============

  /// Validate that field is not empty
  static String? notEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? minLength(String? value, int length) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < length) {
      return 'Minimum $length characters required';
    }
    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int length) {
    if (value != null && value.length > length) {
      return 'Maximum $length characters allowed';
    }
    return null;
  }

  /// Validate length range
  static String? lengthRange(String? value, int min, int max) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < min) {
      return 'Minimum $min characters required';
    }
    if (value.length > max) {
      return 'Maximum $max characters allowed';
    }
    return null;
  }

  /// Validate project name
  static String? projectName(String? value) {
    return lengthRange(value, 2, 100);
  }

  /// Validate task name
  static String? taskName(String? value) {
    return lengthRange(value, 2, 255);
  }

  /// Validate description (optional)
  static String? description(String? value) {
    if (value != null && value.length > 500) {
      return 'Maximum 500 characters allowed';
    }
    return null;
  }

  // ============ EMAIL VALIDATORS ============

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    if (!RegExp(pattern).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // ============ URL VALIDATORS ============

  /// Validate URL format
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    const pattern =
        r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*)$';
    if (!RegExp(pattern).hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  // ============ NUMBER VALIDATORS ============

  /// Validate number
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (int.tryParse(value) == null && double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value) {
    final numberError = number(value);
    if (numberError != null) return numberError;

    final num = double.tryParse(value!);
    if (num != null && num <= 0) {
      return 'Please enter a positive number';
    }
    return null;
  }

  /// Validate number range
  static String? numberRange(String? value, num min, num max) {
    final numberError = number(value);
    if (numberError != null) return numberError;

    final num = double.tryParse(value!);
    if (num != null) {
      if (num < min) {
        return 'Minimum value is $min';
      }
      if (num > max) {
        return 'Maximum value is $max';
      }
    }
    return null;
  }

  // ============ PASSWORD VALIDATORS ============

  /// Validate password strength
  /// Requirements: at least 1 uppercase, 1 lowercase, 1 number, 1 special char
  static String? passwordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain special character';
    }
    return null;
  }

  /// Validate password confirmation
  static String? passwordConfirm(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ============ PHONE VALIDATORS ============

  /// Validate phone number (basic format)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    const pattern = r'^[0-9]{10,15}$';
    if (!RegExp(
      pattern,
    ).hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]+'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // ============ MULTIPLE VALIDATORS ============

  /// Combine multiple validators
  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  /// Custom validator with message
  static String? custom(
    String? value,
    bool Function(String) test,
    String message,
  ) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (!test(value)) {
      return message;
    }
    return null;
  }
}
