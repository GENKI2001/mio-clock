import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/game_room.dart';
import 'package:mio_clock/puzzles/clock_cipher.dart';
import 'package:mio_clock/widgets/door_dial.dart';

import '../test/full_playthrough_test.dart' show runWalkthrough;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iPhoneシミュレータで全謎からノーマルエンドまで通る', (tester) async {
    await runWalkthrough(tester, onDevice: true);
  });

  testWidgets('iPhoneシミュレータで扉前から真エンドへ通る', (tester) async {
    String? ending;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 1280,
                height: 720,
                child: GameRoom(
                  progress: GameProgress.readyAtDoor(),
                  endings: const {'normal'},
                  soundOn: false,
                  onSoundChanged: (_) {},
                  onSave: (_) {},
                  onTitle: () {},
                  onRestart: () {},
                  onEnding: (kind) => ending = kind,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
    expect(ending, 'true');
  });

  testWidgets('iPhoneシミュレータでBGMを開始・停止できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameRoom(
            progress: GameProgress(introSeen: true),
            endings: const {},
            soundOn: true,
            onSoundChanged: (_) {},
            onSave: (_) {},
            onTitle: () {},
            onRestart: () {},
            onEnding: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });
}
