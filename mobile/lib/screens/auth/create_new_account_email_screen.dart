import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_sign_in_service.dart';
import 'dialogs_error.dart';

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
  bool _isGoogleLoading = false;

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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              fontFamily: 'ProductSans',
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
                          fontFamily: 'ProductSans',
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
                        isLoading: _isGoogleLoading,
                        onPressed: _isGoogleLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isGoogleLoading = true;
                                });
                                try {
                                  final result = await GoogleSignInService
                                      .signInAndCheckUser();
                                  if (result['exists'] == true) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => UserExistsDialog(
                                          email: result['email']),
                                    );
                                  } else {
                                    // Store Google user info in prefs for later account creation
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                        'signup_email', result['email']);
                                    await prefs.setString('signup_fullName',
                                        result['name'] ?? '');
                                    await prefs.setString('signup_username',
                                        result['email'].split('@')[0]);

                                    // Show success snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Center(
                                          heightFactor: 1,
                                          child: Text(
                                            'Google sign-in successful',
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
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );

                                    // Navigate to phone number/OTP screen
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/signup_step3_sendotp',
                                      arguments: {
                                        'fromGoogle': true,
                                        'email': result['email'],
                                        'name': result['name'] ?? '',
                                      },
                                    );
                                    return;
                                  }
                                } catch (e) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => SignInFailedDialog(
                                        error: 'Google sign-in failed: ' +
                                            e.toString()),
                                  );
                                } finally {
                                  setState(() {
                                    _isGoogleLoading = false;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  color: Colors.black45,
                                  fontSize: 13),
                              children: const [
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

// Dialog for user already exists
class UserExistsDialog extends StatelessWidget {
  final String email;
  const UserExistsDialog({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        children: [
          Padding(
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
                  'User Already Exists',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Color(0xFF7C1EFF),
                    fontFamily: 'ProductSans',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'A user already exists with this email ($email). Please log in.',
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontFamily: 'ProductSans'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ).copyWith(
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color?>(
                        (states) => null,
                      ),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shadowColor:
                          MaterialStateProperty.all<Color>(Colors.transparent),
                      surfaceTintColor:
                          MaterialStateProperty.all<Color>(Colors.transparent),
                      overlayColor: MaterialStateProperty.all<Color>(
                        const Color(0x1A7C3AED),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF7C1EFF)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// Generic error dialog for signup
class SignupErrorDialog extends StatelessWidget {
  final String error;
  const SignupErrorDialog({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFD32F2F), size: 60),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Color(0xFFD32F2F),
                    fontFamily: 'ProductSans',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontFamily: 'ProductSans'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF7C1EFF)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountCreatedDialog extends StatefulWidget {
  final String email;
  const AccountCreatedDialog({Key? key, required this.email}) : super(key: key);

  @override
  _AccountCreatedDialogState createState() => _AccountCreatedDialogState();
}

class _AccountCreatedDialogState extends State<AccountCreatedDialog> {
  late final String email;
  int secondsLeft = 3;

  @override
  void initState() {
    super.initState();
    email = widget.email;
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
      child: Stack(
        children: [
          Padding(
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
                    fontFamily: 'ProductSans',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'You have successfully created an account with $email. You can now access all features of TatkalPro.',
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontFamily: 'ProductSans'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'Redirecting in $secondsLeft sec',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7C1EFF),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'ProductSans',
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF7C1EFF)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;

  const _SocialButton({
    Key? key,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
    this.color,
    this.isLoading = false,
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
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(color ?? Colors.black),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: iconAsset.endsWith('.svg')
                        ? SvgPicture.asset(iconAsset)
                        : Image.asset(iconAsset, fit: BoxFit.contain),
                  ),
                ],
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    color: color ?? Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
