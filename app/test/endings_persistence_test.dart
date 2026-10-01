import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/data/story_text.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/main.dart';
import 'package:mio_clock/widgets/dialogue_panel.dart';
import 'package:mio_clock/widgets/ending_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('扉の前のセーブから結末まで進むと、印が残りセーブは消える', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'mio100.save.v2': GameProgress.readyAtDoor().toJson(),
      'mio100.sound.v1': false,
    });
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(MioApp(preferences: preferences));
    expect(find.text('つづきから'), findsOneWidget);
    await tester.tap(find.text('つづきから'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('hotspot-door')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    for (var index = 0; index < 10; index++) {
      if (find.byType(DialoguePanel).evaluate().isEmpty) break;
      await tester.tap(find.byType(DialoguePanel));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('watch-button')));
    await tester.pump();
    for (var index = 0; index < 10; index++) {
      if (find.byType(DialoguePanel).evaluate().isEmpty) break;
      await tester.tap(find.byType(DialoguePanel));
      await tester.pump();
    }
    expect(find.byType(EndingScreen), findsOneWidget);
    for (var index = 0; index < normalEndingLines.length; index++) {
      await tester.tapAt(const Offset(640, 250));
      await tester.pump();
    }
    await tester.tap(find.text('タイトルへ戻る'));
    await tester.pump();
    expect(find.textContaining('またね'), findsWidgets);
    expect(find.text('つづきから'), findsOneWidget);
    expect(preferences.getStringList('mio100.endings.v1'), contains('normal'));
    expect(preferences.getString('mio100.save.v2'), isNull);
    expect(tester.takeException(), isNull);
  });
}
