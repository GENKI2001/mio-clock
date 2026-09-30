import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/data/story_text.dart';
import 'package:mio_clock/widgets/ending_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .views
        .first
        .physicalSize = const Size(
      1280,
      720,
    );
    TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .views
            .first
            .devicePixelRatio =
        1;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize();
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetDevicePixelRatio();
  });

  for (final kind in ['normal', 'true']) {
    testWidgets('$kind ending reaches its title card and returns', (
      tester,
    ) async {
      var finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EndingScreen(
              kind: kind,
              soundOn: false,
              onFinish: () => finished = true,
            ),
          ),
        ),
      );
      final lineCount = kind == 'normal'
          ? normalEndingLines.length
          : trueEndingLines.length;
      for (var index = 0; index < lineCount; index++) {
        await tester.tapAt(const Offset(640, 250));
        await tester.pump();
      }
      expect(
        find.text(kind == 'normal' ? 'NORMAL END' : 'TRUE END'),
        findsOneWidget,
      );
      await tester.tap(find.text('タイトルへ戻る'));
      await tester.pump();
      expect(finished, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
