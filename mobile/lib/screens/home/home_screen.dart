import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:train_booking_app/screens/home/tabs/search_tab.dart';
import 'package:train_booking_app/screens/home/tabs/bookings_tab.dart';
import 'package:train_booking_app/screens/home/tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    SearchTab(),
    BookingsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return NeumorphicBackground(
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 8,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(0)),
        ),
        child: Column(
          children: [
            Expanded(child: _tabs[_currentIndex]),
            Neumorphic(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              style: NeumorphicStyle(
                depth: 6,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(32)),
                color: const Color(0xFFE0E5EC),
              ),
              child: NeumorphicToggle(
                height: 60,
                selectedIndex: _currentIndex,
                displayForegroundOnlyIfSelected: true,
                children: [
                  ToggleElement(
                    background: Center(child: Icon(Icons.search)),
                    foreground: Center(child: Icon(Icons.search, color: Colors.blue)),
                  ),
                  ToggleElement(
                    background: Center(child: Icon(Icons.confirmation_number)),
                    foreground: Center(child: Icon(Icons.confirmation_number, color: Colors.blue)),
                  ),
                  ToggleElement(
                    background: Center(child: Icon(Icons.person)),
                    foreground: Center(child: Icon(Icons.person, color: Colors.blue)),
                  ),
                ],
                thumb: Neumorphic(
                  style: NeumorphicStyle(
                    color: Colors.blue[200],
                    depth: 4,
                  ),
                ),
                onChanged: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
