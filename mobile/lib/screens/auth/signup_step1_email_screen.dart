import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tatkalpro/screens/auth/create_new_account_email_screen.dart';
import 'package:tatkalpro/screens/auth/dialogs_error.dart';
import 'package:tatkalpro/utils/validators.dart';
import '../../api_constants.dart';

SnackBar customPurpleSnackbar(String message) {
  return SnackBar(
    content: Center(
      heightFactor: 1,
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF7C1EFF),
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    ),
    backgroundColor: Colors.white,
    behavior: SnackBarBehavior.floating,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    duration: const Duration(seconds: 2),
  );
}

class SignupStep1EmailScreen extends StatefulWidget {
  const SignupStep1EmailScreen({Key? key}) : super(key: key);

  @override
  State<SignupStep1EmailScreen> createState() => _SignupStep1EmailScreenState();
}

class _SignupStep1EmailScreenState extends State<SignupStep1EmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isValid = false;

  void _validateEmail(String value) {
    setState(() {
      _isValid = Validators.isValidEmail(value);
    });
  }

  Future<bool> _checkUserExists(String email) async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/v1/dynamodb/users/exists/$email');
    bool exists = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        exists = jsonDecode(response.body)['exists'] as bool;
      }
    } catch (e) {}
    Navigator.of(context, rootNavigator: true).pop(); // Remove loading
    return exists;
  }

  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    // Store email, username, and full name in session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signup_email', email);
    final username = email.split('@')[0]; // fallback username
    await prefs.setString('signup_username', username);
    await prefs.setString('signup_fullName', username); // fallback fullName
    // Check if user exists first
    final exists = await _checkUserExists(email);
    if (exists) {
      await showDialog(
        context: context,
        builder: (context) => UserExistsDialog(email: email),
      );
      return;
    }
    final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/ses/send-otp');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      Navigator.of(context).pop(); // Remove loading
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          customPurpleSnackbar('OTP sent to your email!'),
        );
        Navigator.pushNamed(context, '/signup_step2');
      } else {
        final error =
            jsonDecode(response.body)['detail'] ?? 'Failed to send OTP';
        await showDialog(
          context: context,
          builder: (context) => const SignupFailedDialog(),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (context) => const SignupFailedDialog(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            const Text('Step 1/4',
                                style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 15,
                                    color: Colors.deepPurple)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _SignupProgressBar(
                                    currentStep: 1, totalSteps: 4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Add Your Email',
                            style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text('Enter your email address to begin signup.',
                            style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontSize: 16,
                                color: Colors.black87)),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.black54, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF7C1EFF), width: 2),
                              ),
                              helperText:
                                  'We’ll send a verification code to this email.',
                            ),
                            validator: (value) {
                              final email = value ?? '';
                              if (email.isEmpty) return 'Email is required';
                              if (!Validators.isValidEmail(email))
                                return 'Enter a valid email';
                              return null;
                            },
                            onChanged: _validateEmail,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _isValid
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF7C1EFF),
                                        Color(0xFFB983FF)
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                  : null,
                              color:
                                  _isValid ? null : Colors.deepPurple.shade100,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _isValid
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.10),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: (_isValid && !_isLoading)
                                    ? () {
                                        if (_formKey.currentState!.validate()) {
                                          _sendOtp();
                                        }
                                      }
                                    : null,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text(
                                            'Proceed',
                                            style: TextStyle(
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Progress bar widget
class _SignupProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _SignupProgressBar(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    double percent = currentStep / totalSteps;
    return SizedBox(
      width: 60,
      height: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent,
          backgroundColor: Colors.deepPurple.shade100,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C1EFF)),
        ),
      ),
    );
  }
}
