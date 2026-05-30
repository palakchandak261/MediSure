import 'package:flutter/material.dart';

/// Shared WavePainter used across multiple screens.
/// Extracted to avoid duplication.
class WavePainter extends CustomPainter {
  final Color color;
  const WavePainter({this.color = const Color(0x1AFFFFFF)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.3,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.7,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Gradient scaffold background used across screens.
/// Wraps content with the standard MediSure gradient + wave decoration.
class GradientScaffoldBackground extends StatelessWidget {
  final Widget child;
  final List<Color> colors;

  const GradientScaffoldBackground({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF6B7FED),
      Color(0xFF8B6FDB),
      Color(0xFFAD65C8),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // Decorative particles
          ...List.generate(30, (index) {
            return Positioned(
              left: (index * 37.0) % MediaQuery.of(context).size.width,
              top: (index * 53.0) % MediaQuery.of(context).size.height,
              child: Container(
                width: 4 + (index % 4) * 3,
                height: 4 + (index % 4) * 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          // Wave at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 200),
              painter: const WavePainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
