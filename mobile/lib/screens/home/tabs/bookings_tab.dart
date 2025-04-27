import 'package:flutter/material.dart';

class BookingsTab extends StatelessWidget {
  const BookingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
              labelColor: Colors.blue,
            ),
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
    );
  }

  Widget _buildBookingsList({required bool upcoming}) {
    // TODO: Fetch bookings from API
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 0, // Replace with actual booking count
      itemBuilder: (context, index) {
        return const Card(
          child: ListTile(
            title: Text('PNR: 1234567890'),
            subtitle: Text('Delhi → Mumbai\n12 May 2025'),
            trailing: Text('CNF/B2/34'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
