import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:train_booking_app/screens/splash_screen.dart';
import 'package:train_booking_app/screens/pre_splash_screen.dart';
import 'package:train_booking_app/screens/auth/login_screen.dart';
import 'package:train_booking_app/screens/home/home_screen.dart';
import 'package:train_booking_app/screens/welcome_screen.dart';
import 'package:train_booking_app/screens/auth/login_with_email_screen.dart';
import 'package:train_booking_app/screens/auth/create_new_account_email_screen.dart';
import 'package:train_booking_app/screens/auth/signup_step1_email_screen.dart';
import 'package:train_booking_app/screens/auth/signup_step3_sendotp_screen.dart';
import 'package:train_booking_app/screens/auth/signup_step2_verify_email_screen.dart';
import 'package:train_booking_app/screens/auth/signup_step3_password_screen.dart';
import 'package:train_booking_app/screens/wallet_screen.dart';

void main() {
  runApp(
    Theme(
      data: ThemeData(fontFamily: 'ProductSans'),
      child: TrainBookingApp(),
    ),
  );
}

class TrainBookingApp extends StatefulWidget {
  @override
  State<TrainBookingApp> createState() => _TrainBookingAppState();
}

class _TrainBookingAppState extends State<TrainBookingApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate loading resources, auth, etc.
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicApp(
      debugShowCheckedModeBanner: false,
      title: 'Train Booking App',
      theme: const NeumorphicThemeData(
        baseColor: Color(0xFF6C3DD8), // purple base
        accentColor: Color(0xFF9C27B0), // purple accent
        variantColor: Colors.white,
        lightSource: LightSource.topLeft,
        depth: 10,
      ),
      darkTheme: const NeumorphicThemeData(
        baseColor: Color(0xFF2D1457),
        accentColor: Color(0xFF9C27B0),
        variantColor: Colors.white,
        lightSource: LightSource.topLeft,
        depth: 6,
      ),
      themeMode: ThemeMode.system,
      home: _isLoading ? const PreSplashScreen() : const WelcomeScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/login_email': (context) => const LoginWithEmailScreen(),
        '/create_new_account': (context) => const CreateNewAccountEmailScreen(),
        '/create_new_account_email': (context) =>
            const CreateNewAccountEmailScreen(),
        '/signup_step1': (context) => const SignupStep1EmailScreen(),
        '/signup_step2': (context) => const SignupStep2VerifyEmailScreen(),
        '/signup_step3': (context) => const SignupStep3PasswordScreen(),
        '/signup_step3_password': (context) =>
            const SignupStep3PasswordScreen(),
        '/signup_step3_mobile_otp': (context) => SignupStep3SendOtpScreen(),
        '/signup_step3_sendotp': (context) => SignupStep3SendOtpScreen(),
        '/wallet': (context) => const WalletScreen(),
      },
    );
  }
}
