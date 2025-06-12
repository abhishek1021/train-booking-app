import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/foundation.dart';
import 'package:tatkalpro/screens/splash_screen.dart';
import 'package:tatkalpro/screens/pre_splash_screen.dart';
import 'package:tatkalpro/screens/auth/login_screen.dart';
import 'package:tatkalpro/screens/home/home_screen.dart';
import 'package:tatkalpro/screens/welcome_screen.dart';
import 'package:tatkalpro/screens/auth/login_with_email_screen.dart';
import 'package:tatkalpro/screens/auth/create_new_account_email_screen.dart';
import 'package:tatkalpro/screens/auth/signup_step1_email_screen.dart';
import 'package:tatkalpro/screens/auth/signup_step3_sendotp_screen.dart';
import 'package:tatkalpro/screens/auth/signup_step2_verify_email_screen.dart';
import 'package:tatkalpro/screens/auth/signup_step3_password_screen.dart';
import 'package:tatkalpro/screens/wallet_screen.dart';
import 'package:tatkalpro/screens/notification_screen.dart';
// Import appropriate notification service based on platform
import 'package:tatkalpro/services/notification_service.dart' if (dart.library.html) 'package:tatkalpro/services/notification_service_web.dart';

// Import Firebase packages
import 'package:firebase_core/firebase_core.dart';

// Import Firebase options
import 'package:tatkalpro/firebase_options.dart' if (dart.library.html) 'package:tatkalpro/firebase_options_web.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on mobile platforms
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize notification service only on mobile platforms
    await NotificationService().initialize();
  } else {
    print('Running on web platform - Firebase initialization skipped');
  }
  
  runApp(
    Theme(
      data: ThemeData(fontFamily: 'ProductSans'),
      child: TatkalProApp(),
    ),
  );
}

class TatkalProApp extends StatefulWidget {
  @override
  State<TatkalProApp> createState() => _TatkalProAppState();
}

class _TatkalProAppState extends State<TatkalProApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate loading resources, auth, etc.
      await Future.delayed(const Duration(seconds: 2));
      
      // Listen for notification events
      NotificationService().notificationStream.listen((notificationData) {
        // Handle notification tap
        print('Notification tapped: $notificationData');
        
        // Navigate to appropriate screen based on notification type
        if (notificationData.containsKey('notification_type')) {
          String type = notificationData['notification_type'];
          switch (type) {
            case 'booking':
              if (notificationData.containsKey('reference_id')) {
                // Navigate to booking details
                // Navigator.of(context).pushNamed('/booking-details', arguments: notificationData['reference_id']);
              } else {
                Navigator.of(context).pushNamed('/notifications');
              }
              break;
            case 'wallet':
              Navigator.of(context).pushNamed('/wallet');
              break;
            default:
              Navigator.of(context).pushNamed('/notifications');
              break;
          }
        } else {
          Navigator.of(context).pushNamed('/notifications');
        }
      });
    } catch (e) {
      print('Error initializing app: $e');
    }
    
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
      title: 'TatkalPro',
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
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}
