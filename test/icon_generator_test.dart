// アプリアイコン PNG を生成するテスト。
// 実行: flutter test test/icon_generator_test.dart --update-goldens
// 生成物: test/goldens/app_icon.png
// → assets/icon/app_icon.png にコピーしてから
//   dart run flutter_launcher_icons を実行する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_management_app/widgets/app_icon_painter.dart';

void main() {
  testWidgets('generate app icon 1024x1024', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomPaint(
            painter: const AppIconPainter(dotsProgress: 1.0, centerProgress: 1.0),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CustomPaint).first,
      matchesGoldenFile('goldens/app_icon.png'),
    );
  });
}
