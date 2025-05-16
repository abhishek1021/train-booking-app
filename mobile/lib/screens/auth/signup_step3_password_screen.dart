import 'package:flutter/material.dart';
import 'package:train_booking_app/utils/validators.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_constants.dart';
import 'package:train_booking_app/screens/auth/create_new_account_email_screen.dart';

class SignupStep3PasswordScreen extends StatefulWidget {
  const SignupStep3PasswordScreen({Key? key}) : super(key: key);

  @override
  State<SignupStep3PasswordScreen> createState() =>
      _SignupStep3PasswordScreenState();
}

class _SignupStep3PasswordScreenState extends State<SignupStep3PasswordScreen> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isValid = false;
  String? _errorText;
  Map<String, bool> _criteria = {
    'min8': false,
    'uppercase': false,
    'number': false,
    'special': false,
  };

  void _validatePassword(String value) {
    setState(() {
      _criteria['min8'] = value.length >= 8;
      _criteria['uppercase'] = value.contains(RegExp(r'[A-Z]'));
      _criteria['number'] = value.contains(RegExp(r'[0-9]'));
      _criteria['special'] = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      _isValid = !_criteria.containsValue(false);
      _errorText = null;
    });
  }

  String? _phone;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['phone'] != null) {
      _phone = args['phone'] as String;
    } else if (_phone == null) {
      // fallback: try to get from shared preferences
      SharedPreferences.getInstance().then((prefs) {
        setState(() {
          _phone = prefs.getString('signup_mobile');
        });
      });
    }
  }

  Future<void> _finishSignupApi() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('signup_email');
    final username = prefs.getString('signup_username');
    final fullName = prefs.getString('signup_fullName');
    final phone = _phone ?? prefs.getString('signup_mobile');
    if (email == null || username == null || fullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Missing signup details. Please restart signup.')),
      );
      return;
    }
    final password = _passwordController.text.trim();
    final userId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/dynamodb/users/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'PK': 'USER#$email',
          'SK': 'PROFILE',
          'UserID': userId,
          'Email': email,
          'Username': username,
          'PasswordHash': password,
          'CreatedAt': now,
          'IsActive': true,
          'OtherAttributes': {'FullName': fullName, 'Role': 'user'},
          'Phone': phone,
        }),
      );
      Navigator.of(context).pop();
      if (response.statusCode == 201) {
        // Store user info in prefs
        final userInfo = jsonDecode(response.body);
        await prefs.setString(
            'user_profile', jsonEncode(userInfo['user'] ?? userInfo));
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AccountCreatedDialog(email: email),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        final error =
            jsonDecode(response.body)['detail'] ?? 'Failed to create user';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _finishSignup() {
    if (_isValid) {
      _finishSignupApi();
    } else {
      setState(() {
        _errorText = 'Please meet all password requirements.';
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
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
                            const Text('Step 4/4',
                                style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 15,
                                    color: Colors.deepPurple)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _SignupProgressBar(
                                    currentStep: 4, totalSteps: 4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Create Your Password',
                            style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text('Set a secure password for your account.',
                            style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontSize: 16,
                                color: Colors.black87)),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'ProductSans'),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'ProductSans'),
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
                            errorText: _errorText,
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onChanged: _validatePassword,
                        ),
                        const SizedBox(height: 16),
                        _PasswordCriteriaChecklist(criteria: _criteria),
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
                                onTap: _isValid ? _finishSignup : null,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'Finish Signup',
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

class _PasswordCriteriaChecklist extends StatelessWidget {
  final Map<String, bool> criteria;
  const _PasswordCriteriaChecklist({required this.criteria});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _criteriaRow('At least 8 characters', criteria['min8'] ?? false),
        _criteriaRow('1 uppercase letter', criteria['uppercase'] ?? false),
        _criteriaRow('1 number', criteria['number'] ?? false),
        _criteriaRow('1 special character', criteria['special'] ?? false),
      ],
    );
  }

  Widget _criteriaRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.radio_button_unchecked,
              color: met ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 14,
                  color: met ? Colors.green : Colors.black54)),
        ],
      ),
    );
  }
}

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
