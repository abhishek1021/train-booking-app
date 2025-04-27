import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:train_booking_app/screens/splash_screen.dart';
import 'package:train_booking_app/screens/auth/login_screen.dart';
import 'package:train_booking_app/screens/home/home_screen.dart';

void main() {
  runApp(const TrainBookingApp());
}

class TrainBookingApp extends StatelessWidget {
  const TrainBookingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NeumorphicApp(
      title: 'Train Booking App',
      theme: const NeumorphicThemeData(
        baseColor: Color(0xFFE0E5EC),
        lightSource: LightSource.topLeft,
        depth: 10,
      ),
      darkTheme: const NeumorphicThemeData(
        baseColor: Color(0xFF222831),
        lightSource: LightSource.topLeft,
        depth: 6,
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
