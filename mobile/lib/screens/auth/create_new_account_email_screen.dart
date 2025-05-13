import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_constants.dart';
import 'google_sign_in_service.dart';

class CreateNewAccountEmailScreen extends StatefulWidget {
  const CreateNewAccountEmailScreen({Key? key}) : super(key: key);

  @override
  State<CreateNewAccountEmailScreen> createState() =>
      _CreateNewAccountEmailScreenState();
}

class _CreateNewAccountEmailScreenState
    extends State<CreateNewAccountEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
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
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Create new account',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create your free TatkalPro account to book IRCTC Tatkal tickets instantly. Save traveler details, manage bookings, and get faster access to trains—all in one place.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C1EFF), Color(0xFFB983FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              Navigator.pushNamed(context, '/signup_step1');
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'Continue with email',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('or',
                                style: TextStyle(color: Colors.black45)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SocialButton(
                        label: 'Continue with Google',
                        iconAsset: 'assets/icons/google.svg',
                        color: Color(0xFFEA4335),
                        onPressed: () async {
                          try {
                            final result =
                                await GoogleSignInService.signInAndCheckUser();
                            if (result['exists'] == true) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) =>
                                    _UserExistsDialog(email: result['email']),
                              );
                            } else {
                              // Proceed with registration logic for Google user
                              final created = await GoogleSignInService
                                  .createUserWithGoogle(
                                email: result['email'],
                                name: result['name'] ?? '',
                              );
                              if (created) {
                                // Fetch user profile from DynamoDB and store in prefs
                                try {
                                  final profileResp = await http.get(
                                    Uri.parse(
                                        '${ApiConstants.baseUrl}/api/v1/dynamodb/users/profile/${result['email']}'),
                                  );
                                  if (profileResp.statusCode == 200) {
                                    final userInfo =
                                        jsonDecode(profileResp.body);
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                        'user_profile',
                                        jsonEncode(
                                            userInfo['user'] ?? userInfo));
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) =>
                                          _AccountCreatedDialog(
                                        email: result['email'],
                                      ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Error'),
                                        content: const Text(
                                            'Could not fetch user profile after signup.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Error'),
                                      content: Text(
                                          'Error fetching user profile: $e'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Signup Failed'),
                                    content: const Text(
                                        'Failed to create account. Please try again.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sign-In Failed'),
                                content: Text('Google sign-in failed: $e'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                  fontFamily: 'Lato',
                                  color: Colors.black45,
                                  fontSize: 13),
                              children: [
                                TextSpan(
                                    text:
                                        'By using TatkalPro, you agree to the '),
                                TextSpan(
                                    text: 'Terms',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                TextSpan(text: ' and '),
                                TextSpan(
                                    text: 'Privacy Policy.',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                              ],
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
    );
  }
}

class _AccountCreatedDialog extends StatefulWidget {
  final String email;
  const _AccountCreatedDialog({Key? key, required this.email})
      : super(key: key);

  @override
  State<_AccountCreatedDialog> createState() => _AccountCreatedDialogState();
}

class _AccountCreatedDialogState extends State<_AccountCreatedDialog> {
  int secondsLeft = 10;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (secondsLeft > 1) {
        setState(() {
          secondsLeft--;
        });
        _startCountdown();
      } else {
        Navigator.of(context).pop();
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF7C1EFF).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(24),
              child: Icon(Icons.check_circle_rounded,
                  color: Color(0xFF7C1EFF), size: 72),
            ),
            const SizedBox(height: 28),
            const Text(
              'Account Created Successfully!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF7C1EFF),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You have successfully created an account with ${widget.email}. You can now access all features of TatkalPro.',
              style: const TextStyle(
                  fontSize: 15, color: Colors.black87, fontFamily: 'Lato'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Redirecting in $secondsLeft sec',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF7C1EFF),
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserExistsDialog extends StatelessWidget {
  final String email;
  const _UserExistsDialog({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF7C1EFF).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(24),
              child: Icon(Icons.info_outline_rounded,
                  color: Color(0xFF7C1EFF), size: 60),
            ),
            const SizedBox(height: 28),
            const Text(
              'User Already Exists',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF7C1EFF),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'A user already exists with this email (${email}). Please log in.',
              style: const TextStyle(
                  fontSize: 15, color: Colors.black87, fontFamily: 'Lato'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C1EFF), Color(0xFFB983FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Center(
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
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
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final VoidCallback onPressed;
  final Color? color;

  const _SocialButton({
    Key? key,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: iconAsset.endsWith('.svg')
                      ? SvgPicture.asset(iconAsset)
                      : Image.asset(iconAsset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    color: color ?? Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
