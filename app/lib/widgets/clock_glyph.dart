import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../puzzles/clock_cipher.dart';

class ClockGlyphView extends StatelessWidget {
  const ClockGlyphView({
    super.key,
    required this.glyph,
    this.size = 68,
    this.face = const Color(0xFFF2E4C2),
    this.ink = const Color(0xFF3E2B1F),
    this.accent = const Color(0xFFA66F3B),
  });

  final ClockGlyph glyph;
  final double size;
  final Color face;
  final Color ink;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: ClockGlyphPainter(
        glyph: glyph,
        face: face,
        ink: ink,
        accent: accent,
      ),
    );
  }
}

class ClockGlyphPainter extends CustomPainter {
  const ClockGlyphPainter({
    required this.glyph,
    required this.face,
    required this.ink,
    required this.accent,
  });

  final ClockGlyph glyph;
  final Color face;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    final scale = radius / 32;

    canvas.drawCircle(center, radius, Paint()..color = face);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * scale,
    );
    canvas.drawCircle(
      center,
      radius - 4 * scale,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale,
    );

    for (var number = 1; number <= 12; number++) {
      final angle = math.pi * (number / 6 - 0.5);
      final marker = Offset(
        center.dx + math.cos(angle) * radius * 0.73,
        center.dy + math.sin(angle) * radius * 0.73,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: number.toString(),
          style: TextStyle(
            color: ink,
            fontSize: 11.5 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        marker - Offset(painter.width / 2, painter.height / 2),
      );
    }

    final hourAngle =
        math.pi *
        (((glyph.hour % 12) + (glyph.minuteMark % 12) / 12) / 6 - 0.5);
    final minuteAngle = math.pi * ((glyph.minuteMark % 12) / 6 - 0.5);
    final hourEnd = Offset(
      center.dx + math.cos(hourAngle) * radius * 0.39,
      center.dy + math.sin(hourAngle) * radius * 0.39,
    );
    final minuteEnd = Offset(
      center.dx + math.cos(minuteAngle) * radius * 0.61,
      center.dy + math.sin(minuteAngle) * radius * 0.61,
    );
    canvas.drawLine(
      center,
      hourEnd,
      Paint()
        ..color = ink
        ..strokeWidth = 3.2 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      minuteEnd,
      Paint()
        ..color = accent
        ..strokeWidth = 1.7 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 2.5 * scale, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(covariant ClockGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.face != face ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent;
}
