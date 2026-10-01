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

  testWidgets('結末を最後まで読むと、隅の小さな札から戻れる', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EndingScreen(
            kind: 'normal',
            soundOn: false,
            onFinish: () => finished = true,
          ),
        ),
      ),
    );
    for (var index = 0; index < normalEndingLines.length; index++) {
      await tester.tapAt(const Offset(640, 250));
      await tester.pump();
    }
    expect(find.text('TRUE END'), findsOneWidget);
    // The card sits in the lower right, leaving the picture uncovered.
    expect(tester.getCenter(find.text('TRUE END')).dx, greaterThan(900));
    await tester.tap(find.text('タイトルへ戻る'));
    await tester.pump();
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });
}
