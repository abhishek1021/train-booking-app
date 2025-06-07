import 'package:flutter/material.dart';
import 'dart:math' as math;

class FailureAnimationDialog extends StatefulWidget {
  final String message;
  final VoidCallback onAnimationComplete;
  final Duration displayDuration;

  const FailureAnimationDialog({
    Key? key,
    required this.message,
    required this.onAnimationComplete,
    this.displayDuration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  State<FailureAnimationDialog> createState() => _FailureAnimationDialogState();
}

class _FailureAnimationDialogState extends State<FailureAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );

    // Start the animation
    _controller.forward();

    // Set up a timer to dismiss the dialog after the specified duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated X mark
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CustomPaint(
                        painter: XMarkPainter(
                          animation: _animation.value,
                          color: Colors.red,
                          strokeWidth: 4.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class XMarkPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double strokeWidth;

  XMarkPainter({
    required this.animation,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the circle
    final double circleAnimation = math.min(1.0, animation * 1.5);
    final double circleRadius = size.width / 2;

    final Path circlePath = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: circleRadius,
        ),
        0,
        2 * math.pi * circleAnimation,
      );

    canvas.drawPath(circlePath, paint);

    // Only start drawing the X mark after the circle is 60% complete
    if (animation > 0.6) {
      // Calculate X animation progress (scale from 0.6-1.0 to 0.0-1.0)
      final double xProgress = (animation - 0.6) / 0.4;

      // Draw the X mark
      final Path xPath = Path();

      // First line of the X (top-left to bottom-right)
      final double firstLineEnd = xProgress < 0.5 ? xProgress * 2 : 1.0;

      xPath.moveTo(
        size.width * 0.3,
        size.height * 0.3,
      );

      xPath.lineTo(
        size.width * 0.3 + (size.width * 0.4) * firstLineEnd,
        size.height * 0.3 + (size.height * 0.4) * firstLineEnd,
      );

      canvas.drawPath(xPath, paint);

      // Second line of the X (top-right to bottom-left)
      if (xProgress > 0.5) {
        final double secondLineProgress = (xProgress - 0.5) * 2;
        final Path secondPath = Path();

        secondPath.moveTo(
          size.width * 0.7,
          size.height * 0.3,
        );

        secondPath.lineTo(
          size.width * 0.7 - (size.width * 0.4) * secondLineProgress,
          size.height * 0.3 + (size.height * 0.4) * secondLineProgress,
        );

        canvas.drawPath(secondPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(XMarkPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
