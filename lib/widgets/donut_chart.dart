import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DonutSegment {
  final String id;
  final Color color;
  final int value;
  const DonutSegment({required this.id, required this.color, required this.value});
}

class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final AppColors colors;
  final double size;
  final double thickness;
  final String centerLabel;
  final String centerValue;

  const DonutChart({
    super.key,
    required this.segments,
    required this.colors,
    this.size = 160,
    this.thickness = 22,
    required this.centerLabel,
    required this.centerValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              segments: segments,
              bgDeep: colors.bgDeep,
              thickness: thickness,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: colors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                centerValue,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final Color bgDeep;
  final double thickness;

  _DonutPainter({required this.segments, required this.bgDeep, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - thickness) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final bgPaint = Paint()
      ..color = bgDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final total = segments.fold<int>(0, (s, seg) => s + seg.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;
    const gap = 0.015;

    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2 * math.pi - gap;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}
