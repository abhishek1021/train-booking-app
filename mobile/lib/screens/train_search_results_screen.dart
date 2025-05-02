import 'package:flutter/material.dart';

class TrainSearchResultsScreen extends StatelessWidget {
  const TrainSearchResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> results = [
      {
        'logo': Icons.train,
        'name': 'Amtrak',
        'type': 'Economy',
        'available': true,
        'price': 40.0,
        'departure': '08:00',
        'arrival': '09:30',
        'from': 'Apex Square',
        'to': 'Proxima',
        'duration': '1h 30m',
        'date': '29 Dec 2023',
      },
      {
        'logo': Icons.train,
        'name': 'Pennsylvania R...',
        'type': 'Economy',
        'available': true,
        'price': 34.0,
        'departure': '09:00',
        'arrival': '10:45',
        'from': 'Apex Square',
        'to': 'Proxima',
        'duration': '1h 45m',
        'date': '29 Dec 2023',
      },
      {
        'logo': Icons.train,
        'name': 'Kansas City So...',
        'type': 'Economy',
        'available': true,
        'price': 42.0,
        'departure': '10:00',
        'arrival': '11:20',
        'from': 'Apex Square',
        'to': 'Proxima',
        'duration': '1h 20m',
        'date': '29 Dec 2023',
      },
      {
        'logo': Icons.train,
        'name': 'Amtrak',
        'type': 'Economy',
        'available': true,
        'price': 40.0,
        'departure': '11:00',
        'arrival': '12:30',
        'from': 'Apex Square',
        'to': 'Proxima',
        'duration': '1h 30m',
        'date': '29 Dec 2023',
      },
      {
        'logo': Icons.train,
        'name': 'MTA NYC',
        'type': 'Economy',
        'available': true,
        'price': 38.0,
        'departure': '12:00',
        'arrival': '13:40',
        'from': 'Apex Square',
        'to': 'Proxima',
        'duration': '1h 40m',
        'date': '29 Dec 2023',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Search Results',
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DateTab(day: 'Mon', date: '27', selected: false),
                _DateTab(day: 'Tue', date: '28', selected: false),
                _DateTab(day: 'Wed', date: '29', selected: true),
                _DateTab(day: 'Thu', date: '30', selected: false),
                _DateTab(day: 'Fri', date: '31', selected: false),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
          // Results list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: results.length,
              itemBuilder: (context, idx) {
                final train = results[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: const Color(0xFF7C3AED).withOpacity(0.15),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFF5F3FF),
                              radius: 18,
                              child: Icon(
                                train['logo'],
                                color: const Color(0xFF7C3AED),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    train['name'],
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return const LinearGradient(
                                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      train['type'],
                                      style: const TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 12,
                                        color: Colors.white, // Will be masked by gradient
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  train['available'] ? 'Available' : 'Full',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w600,
                                    color: train['available'] ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    '\$${train['price'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white, // Will be masked by gradient
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  train['from'],
                                  style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                                ),
                                Text(
                                  train['departure'],
                                  style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7C3AED)),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 2,
                                      color: const Color(0xFF7C3AED),
                                    ),
                                    const Icon(Icons.train, size: 18, color: Color(0xFF7C3AED)),
                                    Container(
                                      width: 32,
                                      height: 2,
                                      color: const Color(0xFF7C3AED),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Duration ${train['duration']}',
                                  style: const TextStyle(fontFamily: 'Lato', fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  train['to'],
                                  style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                                ),
                                Text(
                                  train['arrival'],
                                  style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7C3AED)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              train['date'],
                              style: const TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTab extends StatelessWidget {
  final String day;
  final String date;
  final bool selected;
  const _DateTab({required this.day, required this.date, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Color(0xFF7C3AED) : Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: selected ? Color(0xFF7C3AED) : Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        selected
            ? Container(
                height: 2.5,
                width: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : const SizedBox(height: 2.5, width: 32),
      ],
    );
  }
}
