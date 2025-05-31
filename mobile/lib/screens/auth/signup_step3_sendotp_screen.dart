import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:country_picker/country_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_booking_app/screens/auth/dialogs_error.dart';
import '../../api_constants.dart';
import 'create_new_account_email_screen.dart';
import 'google_sign_in_service.dart';

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

class SignupStep3SendOtpScreen extends StatefulWidget {
  const SignupStep3SendOtpScreen({Key? key}) : super(key: key);

  @override
  State<SignupStep3SendOtpScreen> createState() =>
      _SignupStep3SendOtpScreenState();
}

class _SignupStep3SendOtpScreenState extends State<SignupStep3SendOtpScreen> {
  bool _fromGoogle = false;
  String? _googleEmail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['fromGoogle'] == true) {
      _fromGoogle = true;
      _googleEmail = args['email'] as String?;
    }
  }

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorText;

  Country _selectedCountry = Country(
    phoneCode: '91',
    countryCode: 'IN',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'India',
    example: '9123456789',
    displayName: 'India',
    displayNameNoCountryCode: 'India',
    e164Key: '',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      // Optionally store phone number for later steps
      await prefs.setString('signup_mobile', _phoneController.text.trim());
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/mobile/send-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile':
              '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}'
        }),
      );
      Navigator.of(context).pop(); // Remove loading
      if (response.statusCode == 200) {
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          customPurpleSnackbar('OTP sent to your mobile number'),
        );
      } else {
        final detail = jsonDecode(response.body)['detail']?.toString() ??
            'Failed to send OTP';
        showDialog(
          context: context,
          builder: (context) => WrongOtpDialog(error: detail),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => WrongOtpDialog(error: 'Error: $e'),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      // Always use E.164 format for verification, matching send-otp
      final mobile =
          '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/mobile/verify-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'code': _otpController.text.trim(),
        }),
      );
      Navigator.of(context).pop(); // Remove loading
      if (response.statusCode == 200 &&
          jsonDecode(response.body)['status'] == 'approved') {
        ScaffoldMessenger.of(context).showSnackBar(
          customPurpleSnackbar('Mobile number verified!'),
        );
        if (_fromGoogle) {
          // Store the verified phone number in SharedPreferences for later use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('signup_mobile', mobile);
          final email = _googleEmail ?? prefs.getString('signup_email') ?? '';
          final name = prefs.getString('signup_fullName') ?? '';
          final verifiedMobile = prefs.getString('signup_mobile') ?? mobile;

          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            // Call the API to create the user with Google credentials
            final created = await GoogleSignInService.createUserWithGoogle(
              email: email,
              name: name,
              mobile: verifiedMobile, // Always pass the verified phone number
            );

            // Remove loading indicator
            Navigator.of(context).pop();

            if (created) {
              // Show account created dialog
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AccountCreatedDialog(email: email),
              );
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            } else {
              // Show error dialog if account creation failed
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => SignupErrorDialog(
                  error: 'Failed to create account. Please try again.',
                ),
              );
            }
          } catch (e) {
            // Remove loading indicator and show error
            Navigator.of(context).pop();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => SignupErrorDialog(
                error: 'Error creating account: ${e.toString()}',
              ),
            );
          }
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/signup_step3_password',
            arguments: {
              'phone': mobile,
            },
          );
        }
      } else {
        final detail = jsonDecode(response.body)['detail']?.toString() ??
            'Verification failed';
        showDialog(
          context: context,
          builder: (context) => WrongOtpDialog(error: detail),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => WrongOtpDialog(error: 'Error: $e'),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
            context, '/create_new_account_email', (route) => false);
        return false;
      },
      child: Scaffold(
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
                                onPressed: () =>
                                    Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/create_new_account_email',
                                        (route) => false),
                              ),
                              const SizedBox(width: 8),
                              const Text('Step 3/4',
                                  style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      fontSize: 15,
                                      color: Colors.deepPurple)),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _SignupProgressBar(
                                      currentStep: 3, totalSteps: 4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Verify Your Mobile Number',
                              style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                  color: Colors.black)),
                          const SizedBox(height: 12),
                          const Text(
                              'A 6-digit code will be sent to your mobile. Enter it below to verify.',
                              style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 16,
                                  color: Colors.black87)),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_otpSent,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Mobile Number',
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
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                    left: 4.0, right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showCountryPicker(
                                      context: context,
                                      showPhoneCode: true,
                                      countryListTheme: CountryListThemeData(
                                        flagSize: 24,
                                        backgroundColor: Colors.white,
                                        textStyle: const TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                        bottomSheetHeight: 500,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(18)),
                                        inputDecoration: InputDecoration(
                                          hintText: 'Search country',
                                          hintStyle: const TextStyle(
                                              fontFamily: 'ProductSans'),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Color(0xFF7C3AED),
                                                width: 1),
                                          ),
                                        ),
                                      ),
                                      onSelect: (Country country) {
                                        setState(() {
                                          _selectedCountry = country;
                                        });
                                      },
                                    );
                                  },
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: 80,
                                      maxWidth: 120,
                                      minHeight: 0,
                                      maxHeight: 52,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF7C3AED),
                                            width: 1),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 6.0),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '+${_selectedCountry.phoneCode}',
                                            style: const TextStyle(
                                              fontFamily: 'ProductSans',
                                              fontSize: 16,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Container(
                                            height: 18,
                                            width: 1.2,
                                            color: Color(0xFF7C3AED),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 6),
                                          ),
                                          const Icon(Icons.arrow_drop_down,
                                              color: Colors.black54, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_otpSent)
                            Column(
                              children: [
                                TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'ProductSans'),
                                  decoration: InputDecoration(
                                    labelText: 'OTP Code',
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
                                    counterText: '',
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _otpSent
                                        ? _verifyOtp
                                        : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                ).copyWith(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith<Color?>(
                                    (states) => null,
                                  ),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  overlayColor:
                                      MaterialStateProperty.all<Color>(
                                    const Color(0x1A7C3AED),
                                  ),
                                ),
                                child: Ink(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color(0xFF9F7AEA)
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _otpSent
                                                ? 'Verify OTP'
                                                : 'Send OTP',
                                            style: const TextStyle(
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
