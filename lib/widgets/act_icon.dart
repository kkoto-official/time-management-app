import 'dart:math' as math;
import 'package:flutter/material.dart';

class ActIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color color;

  const ActIcon({super.key, required this.icon, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _IconPainter(icon: icon, color: color),
    );
  }
}

class _IconPainter extends CustomPainter {
  final String icon;
  final Color color;

  _IconPainter({required this.icon, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final s = size.width / 24.0;
    canvas.scale(s, s);

    switch (icon) {
      case 'briefcase':
        _rect(canvas, paint, 3, 7, 18, 13, r: 2);
        _path(canvas, paint, [Offset(9, 7), Offset(9, 5)]);
        _path(canvas, paint, [Offset(9, 5), Offset(11, 3)]);
        // draw rounded rect path for top
        final rrPaint = Paint()..color = color..strokeWidth = paint.strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        final path = Path()..moveTo(9, 5)..lineTo(9, 7)..moveTo(15, 7)..lineTo(15, 5)..lineTo(13, 3)..lineTo(11, 3)..lineTo(9, 3)..lineTo(9, 5);
        canvas.drawPath(path, rrPaint);
        _path(canvas, paint, [Offset(3, 13), Offset(21, 13)]);
        break;
      case 'laptop':
        _rect(canvas, paint, 4, 5, 16, 11, r: 1.5);
        _path(canvas, paint, [Offset(2, 19), Offset(22, 19)]);
        break;
      case 'gamepad':
        _rect(canvas, paint, 2, 7, 20, 10, r: 5);
        _path(canvas, paint, [Offset(6, 11), Offset(10, 11)]);
        _path(canvas, paint, [Offset(8, 9), Offset(8, 13)]);
        _dot(canvas, color, 15, 11, 1.0);
        _dot(canvas, color, 17, 13, 1.0);
        break;
      case 'train':
        _rect(canvas, paint, 5, 3, 14, 14, r: 3);
        _path(canvas, paint, [Offset(5, 11), Offset(19, 11)]);
        _dot(canvas, color, 9, 14, 0.6);
        _dot(canvas, color, 15, 14, 0.6);
        _path(canvas, paint, [Offset(8, 17), Offset(6, 21)]);
        _path(canvas, paint, [Offset(16, 17), Offset(18, 21)]);
        break;
      case 'moon':
        final moonPath = Path()
          ..moveTo(20, 14)
          ..arcToPoint(const Offset(10.5, 4.5), radius: const Radius.circular(8), clockwise: false)
          ..arcToPoint(const Offset(20, 14), radius: const Radius.circular(6));
        canvas.drawPath(moonPath, paint);
        break;
      case 'dots':
        _dot(canvas, color, 6, 12, 1.4);
        _dot(canvas, color, 12, 12, 1.4);
        _dot(canvas, color, 18, 12, 1.4);
        break;
      case 'timer':
        _circle(canvas, paint, 12, 13, 8);
        _path(canvas, paint, [Offset(12, 9), Offset(12, 13), Offset(15, 15)]);
        _path(canvas, paint, [Offset(9, 2), Offset(15, 2)]);
        break;
      case 'home':
        final homePath = Path()
          ..moveTo(3, 11)
          ..lineTo(12, 4)
          ..lineTo(21, 11)
          ..lineTo(21, 21)
          ..lineTo(16, 21)
          ..lineTo(16, 14)
          ..lineTo(8, 14)
          ..lineTo(8, 21)
          ..lineTo(3, 21)
          ..close();
        canvas.drawPath(homePath, paint);
        break;
      case 'chart':
        _path(canvas, paint, [Offset(4, 20), Offset(4, 10)]);
        _path(canvas, paint, [Offset(10, 20), Offset(10, 4)]);
        _path(canvas, paint, [Offset(16, 20), Offset(16, 13)]);
        _path(canvas, paint, [Offset(22, 20), Offset(2, 20)]);
        break;
      case 'gear':
        _circle(canvas, paint, 12, 12, 3);
        _path(canvas, paint, [Offset(12, 2), Offset(12, 5)]);
        _path(canvas, paint, [Offset(12, 19), Offset(12, 22)]);
        _path(canvas, paint, [Offset(2, 12), Offset(5, 12)]);
        _path(canvas, paint, [Offset(19, 12), Offset(22, 12)]);
        for (final deg in [45.0, 135.0, 225.0, 315.0]) {
          final rad = deg * math.pi / 180;
          final x1 = 12 + 5.3 * math.cos(rad);
          final y1 = 12 + 5.3 * math.sin(rad);
          final x2 = 12 + 7.5 * math.cos(rad);
          final y2 = 12 + 7.5 * math.sin(rad);
          _path(canvas, paint, [Offset(x1, y1), Offset(x2, y2)]);
        }
        break;
      case 'play':
        final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
        final playPath = Path()
          ..moveTo(7, 4.5)
          ..lineTo(20, 12)
          ..lineTo(7, 19.5)
          ..close();
        canvas.drawPath(playPath, fillPaint);
        break;
      case 'pause':
        final fillPaint2 = Paint()..color = color..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromLTRBR(6, 4.5, 10, 19.5, const Radius.circular(1)), fillPaint2);
        canvas.drawRRect(RRect.fromLTRBR(14, 4.5, 18, 19.5, const Radius.circular(1)), fillPaint2);
        break;
      case 'stop':
        final fillPaint3 = Paint()..color = color..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromLTRBR(6, 6, 18, 18, const Radius.circular(1.5)), fillPaint3);
        break;
      case 'plus':
        _path(canvas, paint, [Offset(12, 5), Offset(12, 19)]);
        _path(canvas, paint, [Offset(5, 12), Offset(19, 12)]);
        break;
      case 'chevron':
        _path(canvas, paint, [Offset(9, 6), Offset(15, 12), Offset(9, 18)]);
        break;
      case 'chevronL':
        _path(canvas, paint, [Offset(15, 6), Offset(9, 12), Offset(15, 18)]);
        break;
      case 'edit':
        _path(canvas, paint, [Offset(4, 20), Offset(8, 20), Offset(20, 8), Offset(16, 4), Offset(4, 16), Offset(4, 20)]);
        break;
      case 'trash':
        _path(canvas, paint, [Offset(4, 7), Offset(20, 7)]);
        _path(canvas, paint, [Offset(9, 7), Offset(9, 4), Offset(15, 4), Offset(15, 7)]);
        _path(canvas, paint, [Offset(6, 7), Offset(7, 20), Offset(17, 20), Offset(18, 7)]);
        break;
      case 'book':
        _path(canvas, paint, [Offset(4, 4), Offset(10, 4), Offset(12, 7), Offset(12, 20), Offset(10, 18), Offset(4, 18), Offset(4, 4)]);
        _path(canvas, paint, [Offset(20, 4), Offset(14, 4), Offset(12, 7), Offset(12, 20), Offset(14, 18), Offset(20, 18), Offset(20, 4)]);
        break;
      default:
        _dot(canvas, color, 12, 12, 2);
        break;
    }
  }

  void _rect(Canvas canvas, Paint paint, double x, double y, double w, double h, {double r = 0}) {
    canvas.drawRRect(
      RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)),
      paint,
    );
  }

  void _circle(Canvas canvas, Paint paint, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  void _dot(Canvas canvas, Color c, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = c..style = PaintingStyle.fill);
  }

  void _path(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.icon != icon || old.color != color;
}
