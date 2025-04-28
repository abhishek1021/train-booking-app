import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NeumorphicBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Log into account',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Welcome back!\nLet\'s continue your taktal journey',
                  style: TextStyle(
                    fontFamily: 'Lato',
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
                              fontFamily: 'Lato',
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
                      child: Text('or', style: TextStyle(fontFamily: 'Lato', color: Colors.black54)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
                _SocialButton(
                  label: 'Continue with Apple',
                  onPressed: () {},
                  color: Colors.white,
                  borderColor: Colors.black12,
                  iconAsset: 'assets/icons/apple.svg',
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Continue with Instagram',
                  onPressed: () {},
                  color: Colors.white,
                  borderColor: Colors.black12,
                  iconAsset: 'assets/icons/instagram.svg',
                  textColor: Color(0xFF1877F3),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Continue with Google',
                  onPressed: () {},
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
                        style: TextStyle(fontFamily: 'Lato', color: Colors.black45, fontSize: 13),
                        children: [
                          TextSpan(text: 'By using TatkalPro, you agree to the '),
                          TextSpan(text: 'Terms', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color borderColor;
  final Color? textColor;
  final String iconAsset;

  const _SocialButton({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.borderColor,
    required this.iconAsset,
    this.textColor,
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
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Try to load SVG, fallback to Icon if asset not found
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
                    fontFamily: 'Lato',
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
