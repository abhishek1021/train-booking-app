import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  final String greeting;
  final String username;
  final VoidCallback? onNotificationTap;

  const SearchHeader({
    Key? key,
    required this.greeting,
    required this.username,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 330,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    greeting,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontFamilyFallback: [
                        'NotoColorEmoji',
                        'Segoe UI Emoji',
                        'Apple Color Emoji'
                      ],
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onNotificationTap,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.4),
                      color: Colors.white.withOpacity(0.10),
                    ),
                    child: const Icon(Icons.notifications_none_outlined,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              username,
              style: TextStyle(
                fontFamily: 'Lato',
                fontFamilyFallback: ['NotoColorEmoji'],
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
