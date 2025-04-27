import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_booking_app/screens/splash_screen.dart';
import 'package:train_booking_app/screens/auth/login_screen.dart';
import 'package:train_booking_app/screens/home/home_screen.dart';
import 'package:train_booking_app/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TrainBookingApp(),
    ),
  );
}

class TrainBookingApp extends StatelessWidget {
  const TrainBookingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Train Booking App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
