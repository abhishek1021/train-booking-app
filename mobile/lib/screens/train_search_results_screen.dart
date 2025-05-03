import 'package:flutter/material.dart';

class TrainSearchResultsScreen extends StatelessWidget {
  final List<dynamic> trains;
  final String origin;
  final String destination;
  final String date;

  const TrainSearchResultsScreen({
    Key? key,
    required this.trains,
    required this.origin,
    required this.destination,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$origin → $destination', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text(date, style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.normal, fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
      body: trains.isEmpty
          ? Center(child: Text('No trains found.', style: TextStyle(fontFamily: 'Lato', fontSize: 18, color: Colors.black54)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, idx) => SizedBox(height: 18),
              itemCount: trains.length,
              itemBuilder: (context, idx) {
                final train = trains[idx];
                final String trainName = train['train_name'] ?? train['name'] ?? '';
                final String trainNumber = train['train_number']?.toString() ?? '';
                final String sourceStation = train['source_station_name'] ?? train['source_station'] ?? '';
                final String destStation = train['destination_station_name'] ?? train['destination_station'] ?? '';
                final List<dynamic> classes = train['classes_available'] ?? [];
                final List<dynamic> days = train['days_of_run'] ?? [];
                final List<dynamic> route = train['route'] ?? [];
                final List<dynamic> schedule = train['schedule'] ?? [];
                final String depTime = schedule.isNotEmpty ? (schedule.first['departure'] ?? '') : '';
                final String arrTime = schedule.isNotEmpty ? (schedule.last['arrival'] ?? '') : '';
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text('$trainName ($trainNumber)', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Color(0xFF7C3AED).withOpacity(0.1),
                              ),
                              child: Text(classes.join(', '), style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF7C3AED))),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Color(0xFF7C3AED), size: 22),
                            SizedBox(width: 6),
                            Text('$sourceStation → $destStation', style: TextStyle(fontFamily: 'Lato', fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.black38, size: 19),
                            SizedBox(width: 5),
                            Text('Dep: $depTime', style: TextStyle(fontFamily: 'Lato', fontSize: 15, color: Colors.black87)),
                            SizedBox(width: 18),
                            Icon(Icons.flag, color: Colors.black38, size: 19),
                            SizedBox(width: 5),
                            Text('Arr: $arrTime', style: TextStyle(fontFamily: 'Lato', fontSize: 15, color: Colors.black87)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFF7C3AED), size: 19),
                            SizedBox(width: 6),
                            Text('Runs: ${days.join(', ')}', style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: Color(0xFF7C3AED))),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('Route: ${route.join(' → ')}', style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
