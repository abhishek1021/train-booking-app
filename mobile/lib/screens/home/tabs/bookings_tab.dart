import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class BookingsTab extends StatelessWidget {
  const BookingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NeumorphicBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 8,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  NeumorphicText(
                    'My Bookings',
                    style: const NeumorphicStyle(
                      depth: 4,
                      color: Color(0xFF222831),
                    ),
                    textStyle: NeumorphicTextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Neumorphic(
                    style: NeumorphicStyle(depth: -4),
                    child: TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'Past'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBookingsList(upcoming: true),
                        _buildBookingsList(upcoming: false),
                      ],
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

  Widget _buildBookingsList({required bool upcoming}) {
    // TODO: Fetch bookings from API
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 0, // Replace with actual booking count
      itemBuilder: (context, index) {
        return Neumorphic(
          margin: const EdgeInsets.symmetric(vertical: 8),
          style: NeumorphicStyle(
            depth: 4,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          ),
          child: ListTile(
            title: const Text('PNR: 1234567890'),
            subtitle: const Text('Delhi → Mumbai\n12 May 2025'),
            trailing: const Text('CNF/B2/34'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
