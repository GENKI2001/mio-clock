import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/data/story_text.dart';
import 'package:mio_clock/main.dart';
import 'package:mio_clock/puzzles/clock_cipher.dart';
import 'package:mio_clock/widgets/door_dial.dart';
import 'package:mio_clock/widgets/ending_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ノーマル回収後は扉前から真エンドへ進み両印が残る', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'mio100.endings.v1': ['normal'],
      'mio100.sound.v1': false,
    });
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(MioApp(preferences: preferences));
    expect(find.text('扉の前から'), findsOneWidget);
    await tester.tap(find.text('扉の前から'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('hotspot-door')));
    await tester.pump();
    for (final glyph in encodeWord('おかえり')!) {
      var dial = tester.widget<DoorDial>(find.byType(DoorDial));
      dial.onSelectHand(true);
      dial.onSetNumber(glyph.hour);
      dial.onSelectHand(false);
      dial.onSetNumber(glyph.minuteMark);
      await tester.pump();
      dial = tester.widget<DoorDial>(find.byType(DoorDial));
      dial.onStamp();
      await tester.pump();
    }
    tester.widget<DoorDial>(find.byType(DoorDial)).onSay();
    await tester.pump();
    expect(find.byType(EndingScreen), findsOneWidget);
    for (var index = 0; index < trueEndingLines.length; index++) {
      await tester.tapAt(const Offset(640, 250));
      await tester.pump();
    }
    await tester.tap(find.text('タイトルへ戻る'));
    await tester.pump();
    expect(find.textContaining('またね'), findsWidgets);
    expect(find.textContaining('おかえり'), findsWidgets);
    expect(find.text('扉の前から'), findsOneWidget);
    expect(preferences.getStringList('mio100.endings.v1'), contains('true'));
    expect(tester.takeException(), isNull);
  });
}
