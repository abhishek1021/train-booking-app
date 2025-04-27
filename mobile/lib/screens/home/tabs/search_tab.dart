import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeumorphicText(
                    'Search Trains',
                    style: const NeumorphicStyle(
                      depth: 4,
                      color: Color(0xFF222831),
                    ),
                    textStyle: NeumorphicTextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Neumorphic(
                    style: NeumorphicStyle(depth: -4),
                    child: TextFormField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'From Station',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.train),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Neumorphic(
                    style: NeumorphicStyle(depth: -4),
                    child: TextFormField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'To Station',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.train),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDate,
                    child: Neumorphic(
                      style: NeumorphicStyle(depth: -4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Journey Date',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Select Date',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  NeumorphicButton(
                    onPressed: () {
                      // TODO: Implement train search
                    },
                    style: NeumorphicStyle(
                      depth: 6,
                      color: Colors.blue[300],
                      boxShape: NeumorphicBoxShape.stadium(),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Search Trains',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
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
}
