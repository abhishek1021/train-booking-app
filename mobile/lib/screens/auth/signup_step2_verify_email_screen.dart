import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_booking_app/utils/validators.dart';
import '../../api_constants.dart';

class SignupStep2VerifyEmailScreen extends StatefulWidget {
  const SignupStep2VerifyEmailScreen({Key? key}) : super(key: key);

  @override
  State<SignupStep2VerifyEmailScreen> createState() =>
      _SignupStep2VerifyEmailScreenState();
}

class _SignupStep2VerifyEmailScreenState
    extends State<SignupStep2VerifyEmailScreen> {
  final _otpController = TextEditingController();
  bool _isValid = false;
  String? _errorText;

  void _validateOtp(String value) {
    setState(() {
      _isValid = value.length == 6 && Validators.isNumeric(value);
      _errorText = null;
    });
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('signup_email');
    if (email == null) {
      setState(() {
        _errorText = 'Email not found in session.';
      });
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/ses/verify-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      Navigator.of(context).pop(); // Remove loading
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verified!')),
        );
        Navigator.pushNamed(context, '/signup_step3');
      } else {
        final error =
            jsonDecode(response.body)['detail'] ?? 'Invalid or expired OTP';
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Verification Failed'),
            content: Text(error.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          _errorText = error;
        });
      }
    } catch (e) {
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      setState(() {
        _errorText = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
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
                            const Text('Step 2/3',
                                style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 15,
                                    color: Colors.deepPurple)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _SignupProgressBar(
                                    currentStep: 2, totalSteps: 3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Verify Your Email',
                            style: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text(
                            'A 6-digit code has been sent to your email. Enter it below to verify.',
                            style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 16,
                                color: Colors.black87)),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'OTP Code',
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
                            errorText: _errorText,
                            counterText: '',
                          ),
                          onChanged: _validateOtp,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Simulate resend
                                setState(() {
                                  _errorText = null;
                                  _otpController.clear();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('OTP resent to your email.')),
                                );
                              },
                              child: const Text('Resend Code',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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
                                onTap: _isValid ? _verifyOtp : null,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'Verify',
                                      style: TextStyle(
                                        fontFamily: 'Lato',
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
