import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // TODO: Check if user is logged in
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicBackground(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 12,
              boxShape: NeumorphicBoxShape.circle(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Replace with your logo asset if available
                  Icon(Icons.train, size: 80, color: Colors.blue[300]),
                  const SizedBox(height: 24),
                  NeumorphicProgressIndeterminate(
                    style: ProgressStyle(accent: Colors.blue[300]!),
                  ),
                  const SizedBox(height: 16),
                  NeumorphicText(
                    'Train Booking App',
                    style: const NeumorphicStyle(
                      depth: 4,
                      color: Color(0xFF222831),
                    ),
                    textStyle: NeumorphicTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
