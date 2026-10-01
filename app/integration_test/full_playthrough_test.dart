import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/game_room.dart';
import 'package:mio_clock/widgets/dialogue_panel.dart';

import '../test/full_playthrough_test.dart' show runWalkthrough;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iPhoneシミュレータで全謎からノーマルエンドまで通る', (tester) async {
    await runWalkthrough(tester, onDevice: true);
  });

  testWidgets('iPhoneシミュレータで扉の前から結末まで通る', (tester) async {
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
    expect(ending, 'normal');
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
