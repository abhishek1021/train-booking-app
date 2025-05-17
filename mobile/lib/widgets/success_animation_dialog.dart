import 'package:flutter/material.dart';
import 'dart:math' as math;

class SuccessAnimationDialog extends StatefulWidget {
  final String message;
  final VoidCallback onAnimationComplete;
  final Duration displayDuration;

  const SuccessAnimationDialog({
    Key? key,
    required this.message,
    required this.onAnimationComplete,
    this.displayDuration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  State<SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<SuccessAnimationDialog>
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
            // Animated check mark
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C1EFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CustomPaint(
                        painter: CheckmarkPainter(
                          animation: _animation.value,
                          color: const Color(0xFF7C1EFF),
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
                color: Color(0xFF7C1EFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double strokeWidth;

  CheckmarkPainter({
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

    final double checkmarkAnimationValue = math.min(1.0, animation * 1.5);
    
    // Draw the circle
    final double circleAnimation = math.min(1.0, animation * 2);
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

    // Only start drawing the checkmark after the circle is 60% complete
    if (animation > 0.6) {
      // Calculate checkmark animation progress (scale from 0.6-1.0 to 0.0-1.0)
      final double checkProgress = (animation - 0.6) / 0.4;
      
      // Draw the checkmark
      final Path checkPath = Path();
      
      // First line of the checkmark (down-left)
      final double firstLineEnd = checkProgress < 0.5 
          ? checkProgress * 2 
          : 1.0;
          
      checkPath.moveTo(
        size.width * 0.3,
        size.height * 0.5,
      );
      
      checkPath.lineTo(
        size.width * 0.3 + (size.width * 0.15) * firstLineEnd,
        size.height * 0.5 + (size.height * 0.15) * firstLineEnd,
      );
      
      // Second line of the checkmark (up-right)
      if (checkProgress > 0.5) {
        final double secondLineProgress = (checkProgress - 0.5) * 2;
        
        checkPath.lineTo(
          size.width * 0.45 + (size.width * 0.25) * secondLineProgress,
          size.height * 0.65 - (size.height * 0.3) * secondLineProgress,
        );
      }
      
      canvas.drawPath(checkPath, paint);
    }
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
