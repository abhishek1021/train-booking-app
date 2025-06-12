import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_constants.dart';
import 'google_sign_in_service.dart';
import 'package:tatkalpro/screens/auth/dialogs_error.dart';
import 'package:tatkalpro/widgets/success_animation_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    return NeumorphicBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/welcome', (route) => false),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Log into account',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Welcome back!\nLet\'s continue your taktal journey',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 16,
                    color: Colors.black54,
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
                    borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pushNamed(context, '/login_email');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Continue with email',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.white,
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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C1EFF), Color(0xFFB983FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pushNamed(
                          context, 
                          '/signup_step3_sendotp',
                          arguments: {'fromLogin': true}
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Continue with phone number',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('or',
                          style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.black54)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
                _SocialButton(
                  label: _isGoogleLoading
                      ? 'Signing in...'
                      : 'Continue with Google',
                  onPressed: _isGoogleLoading
                      ? null
                      : () async {
                          setState(() => _isGoogleLoading = true);
                          try {
                            final result =
                                await GoogleSignInService.signInAndCheckUser();
                            if (result['exists'] == false) {
                              showDialog(
                                context: context,
                                builder: (context) => _UserNotFoundDialog(
                                  email: result['email'],
                                  name: result['name'],
                                ),
                              );
                            } else {
                              // Fetch user profile and store in prefs
                              try {
                                final profileResp = await http.get(
                                  Uri.parse(
                                      '${ApiConstants.baseUrl}/api/v1/dynamodb/users/profile/${result['email']}'),
                                );
                                if (profileResp.statusCode == 200) {
                                  final userInfo = jsonDecode(profileResp.body);
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  // Store the complete user profile data
                                  await prefs.setString('user_profile',
                                      jsonEncode(userInfo['user'] ?? userInfo));
                                  // Also store token if available
                                  if (result['token'] != null) {
                                    await prefs.setString(
                                        'auth_token', result['token']);
                                  }

                                  // Show success animation before navigating
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                        SuccessAnimationDialog(
                                      message: 'Login Successful',
                                      onAnimationComplete: () {
                                        // Navigate to home screen after animation
                                        Navigator.pushReplacementNamed(
                                            context, '/home');
                                      },
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ProfileFetchErrorDialog(),
                                  );
                                }
                              } catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ProfileFetchErrorDialog(),
                                );
                              }
                            }
                          } catch (e) {
                            showDialog(
                              context: context,
                              builder: (context) => SignInFailedDialog(
                                  error: 'Google sign-in failed: $e'),
                            );
                          } finally {
                            setState(() => _isGoogleLoading = false);
                          }
                        },
                  color: Colors.white,
                  borderColor: Colors.black12,
                  iconAsset: 'assets/icons/google.svg',
                  textColor: Color(0xFFEA4335),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                            fontFamily: 'ProductSans',
                            color: Colors.black45,
                            fontSize: 13),
                        children: [
                          TextSpan(
                              text: 'By using TatkalPro, you agree to the '),
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
  }
}

class _UserNotFoundDialog extends StatefulWidget {
  final String? email;
  final String? name;
  const _UserNotFoundDialog({Key? key, this.email, this.name})
      : super(key: key);

  @override
  State<_UserNotFoundDialog> createState() => _UserNotFoundDialogState();
}

class _UserNotFoundDialogState extends State<_UserNotFoundDialog> {
  bool _isLoading = false;
  String? _error;

  Future<void> _createWithGoogleData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final success = await GoogleSignInService.createUserWithGoogle(
        email: widget.email ?? '',
        name: widget.name ?? '',
      );
      if (success) {
        // Optionally fetch profile and store in prefs
        final profileResp = await http.get(
          Uri.parse(
              '${ApiConstants.baseUrl}/api/v1/dynamodb/users/profile/${widget.email}'),
        );
        if (profileResp.statusCode == 200) {
          final userInfo = jsonDecode(profileResp.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'user_profile', jsonEncode(userInfo['user'] ?? userInfo));
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        } else {
          setState(() {
            _error = 'Could not fetch user profile after creation.';
          });
        }
      } else {
        setState(() {
          _error = 'Failed to create account with Google data.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              child: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF7C1EFF), size: 60),
            ),
            const SizedBox(height: 28),
            const Text(
              'User Not Found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF7C1EFF),
                fontFamily: 'ProductSans',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This user does not exist. You can create an account or use your Google data and we will create an account automatically for you.',
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontFamily: 'ProductSans'),
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
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
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacementNamed(context, '/signup');
                          },
                    child: const Center(
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                ).copyWith(
                  backgroundColor:
                      MaterialStateProperty.all(Colors.transparent),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                ),
                onPressed: _isLoading ? null : _createWithGoogleData,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Create Account with Google Data',
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
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color borderColor;
  final Color? textColor;
  final String iconAsset;
  final bool isLoading;

  const _SocialButton({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.borderColor,
    required this.iconAsset,
    this.textColor,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C1EFF),
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Builder(
                          builder: (context) {
                            try {
                              return SvgPicture.asset(iconAsset);
                            } catch (e) {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          color: textColor ?? Colors.black,
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
