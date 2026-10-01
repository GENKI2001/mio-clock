import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/game_room.dart';
import 'package:mio_clock/widgets/dialogue_panel.dart';

Widget scaledRoom(GameProgress progress) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1280,
          height: 720,
          child: GameRoom(
            progress: progress,
            endings: const {},
            soundOn: false,
            onSoundChanged: (_) {},
            onSave: (_) {},
            onTitle: () {},
            onRestart: () {},
            onEnding: (_) {},
          ),
        ),
      ),
    ),
  ),
);

Future<void> advanceDialogue(WidgetTester tester) async {
  for (var index = 0; index < 80; index++) {
    await tester.pump();
    if (find.byType(DialoguePanel).evaluate().isEmpty) return;
    await tester.tap(find.byType(DialoguePanel));
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('幅667相当でも作業台をのぞいて歯車と缶に触れる', (tester) async {
    tester.view.physicalSize = const Size(667, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final past = GameProgress(era: Era.past, introSeen: true, metMio: true);
    await tester.pumpWidget(scaledRoom(past));
    await tester.tap(find.byKey(const Key('hotspot-workbench')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(find.byKey(const Key('scene-tin'))).width, greaterThan(60));
    await tester.tap(find.byKey(const Key('scene-gear')));
    await tester.pump();
    await advanceDialogue(tester);
    await tester.tap(find.byKey(const Key('scene-tin')));
    await tester.pump();
    await advanceDialogue(tester);
    expect(past.gearInTin, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final future = GameProgress(
      introSeen: true,
      metMio: true,
      gearInTin: true,
      inventory: {'matches'},
    );
    await tester.pumpWidget(scaledRoom(future));
    await tester.tap(find.byKey(const Key('item-matches')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('hotspot-workbench')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('scene-tin')));
    await tester.pump();
    await advanceDialogue(tester);
    expect(future.tinOpened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
