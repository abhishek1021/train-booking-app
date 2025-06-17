import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_constants.dart';
import 'dialogs_error.dart'; // Contains SignInFailedDialog and WrongOtpDialog
import 'package:tatkalpro/widgets/success_animation_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isVerifying = false;

  // --- Custom SnackBar for consistent user feedback ---
  void _showCustomSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: duration,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // --- Validators ---
  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@\$!%*?&])[A-Za-z\d@\$!%*?&]{8,}$').hasMatch(value)) {
      return 'Password must include uppercase, lowercase, number & special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/password/request-reset');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          _otpSent = true;
        });
        _showCustomSnackBar(
          message: 'OTP sent to your email',
          icon: Icons.check_circle,
          backgroundColor: Colors.green[700]!,
        );
      } else {
        String errorMsg;
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['detail'] ?? 'Failed to send OTP';
        } catch (e) {
          // If response body isn't valid JSON
          errorMsg = 'Failed to send OTP: Server error';
        }
        
        // Show appropriate error dialog based on error type
        if (errorMsg.toLowerCase().contains('user not found')) {
          showDialog(
            context: context,
            builder: (context) => SignInFailedDialog(
              error: 'No account found with this email address. Please check the email or create a new account.',
            ),
          );
        } else if (errorMsg.toLowerCase().contains('resource') ||
                 errorMsg.toLowerCase().contains('database')) {
          // Database related errors
          showDialog(
            context: context,
            builder: (context) => SignInFailedDialog(
              error: 'Server error: Unable to process your request. Please try again later or contact support.',
            ),
          );
        } else {
          // All other errors
          showDialog(
            context: context,
            builder: (context) => SignInFailedDialog(error: errorMsg),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => SignInFailedDialog(
          error: 'Unable to connect to the server. Please check your internet connection and try again.',
        ),
      );
    }
  }

  Future<void> _verifyAndResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final otp = _otpController.text.trim();
      final newPassword = _newPasswordController.text;
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/password/verify-reset');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );

      setState(() {
        _isVerifying = false;
      });

      if (response.statusCode == 200) {
        // Show success animation before navigating back
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessAnimationDialog(
            message: 'Password Reset Successful',
            onAnimationComplete: () {
              // Navigate back to login screen
              Navigator.of(context).pop();
            },
          ),
        );
      } else {
        String errorMsg;
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['detail'] ?? 'Failed to reset password';
        } catch (e) {
          // If response body isn't valid JSON
          errorMsg = 'Failed to reset password: Server error';
        }
        
        // Show appropriate error dialog based on error type
        if (errorMsg.toLowerCase().contains('otp') || 
            errorMsg.toLowerCase().contains('verification') ||
            errorMsg.toLowerCase().contains('expired') ||
            errorMsg.toLowerCase().contains('invalid')) {
          // OTP related errors use the WrongOtpDialog
          showDialog(
            context: context,
            builder: (context) => WrongOtpDialog(error: errorMsg),
          );
        } else if (errorMsg.toLowerCase().contains('resource') ||
                 errorMsg.toLowerCase().contains('database')) {
          // Database related errors
          showDialog(
            context: context,
            builder: (context) => SignInFailedDialog(
              error: 'Server error: Unable to process your request. Please try again later or contact support.',
            ),
          );
        } else {
          // All other errors
          showDialog(
            context: context,
            builder: (context) => SignInFailedDialog(error: errorMsg),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      
      // Show error dialog with more user-friendly message
      showDialog(
        context: context,
        builder: (context) => SignInFailedDialog(
          error: 'Error resetting password: Unable to connect to the server. Please check your internet connection and try again.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Enter your email address to receive a verification code. Use the code to reset your password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 72,
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !_otpSent,
                                    style: const TextStyle(
                                      fontFamily: 'ProductSans',
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'example@example.com',
                                      hintStyle: const TextStyle(
                                        color: Colors.black38,
                                        fontFamily: 'ProductSans',
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 18,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Colors.black12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Colors.black26),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Colors.deepPurple),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      errorStyle: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        height: 1.2,
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                
                                if (!_otpSent) ...[
                                  const SizedBox(height: 28),
                                  Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: _isLoading ? null : _requestPasswordReset,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: Center(
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Send OTP',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'ProductSans',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                
                                if (_otpSent) ...[
                                  const SizedBox(height: 20),
                                  const Text(
                                    'OTP',
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 72,
                                    child: TextFormField(
                                      controller: _otpController,
                                      validator: _validateOtp,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        fontFamily: 'ProductSans',
                                        color: Colors.black,
                                        letterSpacing: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '• • • • • •',
                                        hintStyle: const TextStyle(
                                          color: Colors.black38,
                                          fontFamily: 'ProductSans',
                                          letterSpacing: 8,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.black12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.black26),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.deepPurple),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        errorStyle: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          height: 1.2,
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  const Text(
                                    'New Password',
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 72,
                                    child: TextFormField(
                                      controller: _newPasswordController,
                                      validator: _validatePassword,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(
                                        fontFamily: 'ProductSans',
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter new password',
                                        hintStyle: const TextStyle(
                                          color: Colors.black38,
                                          fontFamily: 'ProductSans',
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.black12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.black26),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.deepPurple),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.black38,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        errorStyle: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Confirm Password',
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 72,
                                    child: TextFormField(
                                      controller: _confirmPasswordController,
                                      validator: _validateConfirmPassword,
                                      obscureText: _obscureConfirmPassword,
                                      style: const TextStyle(
                                        fontFamily: 'ProductSans',
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Confirm new password',
                                        hintStyle: const TextStyle(
                                          color: Colors.black38,
                                          fontFamily: 'ProductSans',
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.black12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.black26),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Colors.deepPurple),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.black38,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        errorStyle: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 28),
                                  Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: _isVerifying ? null : _verifyAndResetPassword,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: Center(
                                            child: _isVerifying
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Reset Password',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'ProductSans',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _otpSent = false;
                                          _otpController.clear();
                                          _newPasswordController.clear();
                                          _confirmPasswordController.clear();
                                        });
                                      },
                                      child: const Text(
                                        'Resend OTP',
                                        style: TextStyle(
                                          color: Color(0xFF7C3AED),
                                          fontFamily: 'ProductSans',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
