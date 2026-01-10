import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 20) return; // Don't paint if space is too small

    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 10;
    final y = size.height / 2;
    final endX = size.width - 5;

    while (startX < endX) {
      canvas.drawLine(Offset(startX, y), Offset(startX + 2, y), paint);
      startX += 6;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
