import 'package:flutter/material.dart';
import '../widgets/app_icon_painter.dart';

/// ネイティブスプラッシュ終了後に表示する Flutter 製スプラッシュ。
/// アニメーション完了後に [onDone] を呼び出す。
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // タイムライン（0.0〜1.0）
  //   0.00〜0.50 : ドット10個が順に出現
  //   0.50〜0.75 : 中央時計が出現
  //   0.75〜1.00 : フェードアウト
  static const _totalMs = 2000;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final opacity = t < 0.75 ? 1.0 : 1.0 - ((t - 0.75) / 0.25).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: CustomPaint(
            painter: AppIconPainter(
              dotsProgress:   (t / 0.50).clamp(0.0, 1.0),
              centerProgress: t < 0.50
                  ? 0.0
                  : ((t - 0.50) / 0.25).clamp(0.0, 1.0),
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
