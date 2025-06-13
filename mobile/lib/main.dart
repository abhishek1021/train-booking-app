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
import 'package:tatkalpro/widgets/notification_overlay.dart';

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

  // Global navigator key for navigation from anywhere
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  Future<void> _initializeApp() async {
    try {
      // Simulate loading resources, auth, etc.
      await Future.delayed(const Duration(seconds: 2));
      
      // Listen for notification events
      NotificationService().notificationStream.listen((notificationData) {
        // Handle notification tap
        print('Notification tapped: $notificationData');
        
        // Only handle navigation if the notification was tapped
        if (notificationData.containsKey('tapped') && notificationData['tapped'] == true) {
          // Navigate to appropriate screen based on notification type
          if (notificationData.containsKey('notification_type')) {
            String type = notificationData['notification_type'];
            switch (type) {
              case 'booking':
                if (notificationData.containsKey('reference_id')) {
                  // Navigate to booking details
                  _navigatorKey.currentState?.pushNamed('/notifications');
                } else {
                  _navigatorKey.currentState?.pushNamed('/notifications');
                }
                break;
              case 'wallet':
                _navigatorKey.currentState?.pushNamed('/wallet');
                break;
              default:
                _navigatorKey.currentState?.pushNamed('/notifications');
                break;
            }
          } else {
            _navigatorKey.currentState?.pushNamed('/notifications');
          }
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
    final notificationService = NotificationService();
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TatkalPro',
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: notificationService.scaffoldMessengerKey,
      theme: ThemeData(
        primaryColor: const Color(0xFF7C3AED),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFF9F7AEA),
        ),
        fontFamily: 'ProductSans',
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF2D1457),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D1457),
          primary: const Color(0xFF2D1457),
          secondary: const Color(0xFF9C27B0),
          brightness: Brightness.dark,
        ),
        fontFamily: 'ProductSans',
      ),
      themeMode: ThemeMode.system,
      home: _isLoading 
        ? const PreSplashScreen() 
        : NotificationOverlay(child: const WelcomeScreen()),
      builder: (context, child) {
        return NotificationOverlay(child: child!);
      },
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
