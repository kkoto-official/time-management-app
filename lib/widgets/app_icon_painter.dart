import 'dart:math';
import 'package:flutter/material.dart';

// アクティビティ10種のカラー（kActivities と同順）
const _kDotColors = [
  Color(0xFFB3541B), // workA
  Color(0xFF8A6A2E), // workB
  Color(0xFFA04668), // game
  Color(0xFF4A6B52), // move
  Color(0xFF3D5A80), // sleep
  Color(0xFF2E6E5A), // exercise
  Color(0xFF7A4E28), // meal
  Color(0xFF5B4480), // study
  Color(0xFF4A6870), // rest
  Color(0xFF6B5A4B), // other
];

const _kBgDark   = Color(0xFF6B3A12);
const _kBgMid    = Color(0xFFB8681E);
const _kCenter   = Color(0xFFE8C09A);
const _kHandClr  = Color(0xFF2A1E14);

/// スプラッシュ画面とアイコン生成の共通描画クラス。
/// [dotsProgress] 0→1 でドットが順に出現する。
/// [centerProgress] 0→1 で中央時計が出現する。
class AppIconPainter extends CustomPainter {
  final double dotsProgress;
  final double centerProgress;

  const AppIconPainter({this.dotsProgress = 1.0, this.centerProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final min = size.shortestSide;

    // ── 背景 ──────────────────────────────────────────────
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [_kBgMid, _kBgDark],
        ).createShader(bgRect),
    );

    // ── アクティビティドット ──────────────────────────────
    final n         = _kDotColors.length;
    final dotR      = min * 0.055;
    final ringR     = min * 0.36;

    for (int i = 0; i < n; i++) {
      final p = ((dotsProgress * n) - i).clamp(0.0, 1.0);
      if (p <= 0) continue;

      final angle = (2 * pi * i / n) - pi / 2; // 12時から時計回り
      final dx = cx + ringR * cos(angle);
      final dy = cy + ringR * sin(angle);

      // グロー
      canvas.drawCircle(
        Offset(dx, dy),
        dotR * 1.6 * p,
        Paint()
          ..color = _kDotColors[i].withAlpha((80 * p).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // ドット本体
      canvas.drawCircle(
        Offset(dx, dy),
        dotR * p,
        Paint()..color = _kDotColors[i].withAlpha((255 * p).round()),
      );
    }

    // ── 中央時計 ─────────────────────────────────────────
    if (centerProgress <= 0) return;

    final cp = centerProgress;

    // グロー
    canvas.drawCircle(
      Offset(cx, cy),
      min * 0.18 * cp,
      Paint()
        ..color = _kCenter.withAlpha((50 * cp).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // 白縁
    canvas.drawCircle(
      Offset(cx, cy),
      min * 0.13 * cp,
      Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha((30 * cp).round())
        ..style = PaintingStyle.fill,
    );
    // 中央円
    canvas.drawCircle(
      Offset(cx, cy),
      min * 0.12 * cp,
      Paint()..color = _kCenter.withAlpha((230 * cp).round()),
    );

    // 時計の針（centerProgress > 0.5 から出現）
    if (cp <= 0.5) return;
    final hp = ((cp - 0.5) * 2).clamp(0.0, 1.0);
    final hr  = min * 0.08;
    final handPaint = Paint()
      ..color = _kHandClr.withAlpha((220 * hp).round())
      ..strokeWidth = min * 0.013
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 短針（9時方向）
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx - hr * 0.55 * hp, cy),
      handPaint,
    );
    // 長針（12時方向）
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - hr * hp),
      handPaint,
    );
    // 中心ピン
    canvas.drawCircle(
      Offset(cx, cy),
      min * 0.013,
      Paint()..color = _kHandClr.withAlpha((220 * hp).round()),
    );
  }

  @override
  bool shouldRepaint(AppIconPainter old) =>
      old.dotsProgress != dotsProgress || old.centerProgress != centerProgress;
}
