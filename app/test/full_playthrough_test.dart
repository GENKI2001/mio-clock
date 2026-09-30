import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/game_room.dart';
import 'package:mio_clock/puzzles/clock_cipher.dart';
import 'package:mio_clock/widgets/dialogue_panel.dart';
import 'package:mio_clock/widgets/door_dial.dart';
import 'package:mio_clock/widgets/paper_panel.dart';
import 'package:mio_clock/widgets/puzzle_panels.dart';

Future<void> advanceDialogue(WidgetTester tester) async {
  for (var index = 0; index < 80; index++) {
    await tester.pump();
    if (find.byType(DialoguePanel).evaluate().isEmpty) return;
    await tester.tap(find.byType(DialoguePanel));
    await tester.pump();
  }
  throw StateError('Dialogue did not finish');
}

Future<void> tapHotspot(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('hotspot-$id')));
  await tester.pump();
}

Future<void> closePaper(WidgetTester tester) async {
  tester.widget<PaperPanel>(find.byType(PaperPanel)).onClose();
  await tester.pump();
}

Future<void> unlock(WidgetTester tester, List<int> code) async {
  final lock = tester.widget<NumberLockPanel>(find.byType(NumberLockPanel));
  for (var index = 0; index < code.length; index++) {
    final value = code[index];
    final delta = value > 5 ? -1 : 1;
    final repeats = value > 5 ? 10 - value : value;
    for (var turn = 0; turn < repeats; turn++) {
      lock.onDigit(index, delta);
    }
  }
  await tester.pump();
  lock.onOpen();
  await tester.pump();
}

Future<void> runWalkthrough(
  WidgetTester tester, {
  bool onDevice = false,
}) async {
  if (!onDevice) {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  final progress = GameProgress(introSeen: true);
  String? ending;
  final room = GameRoom(
    progress: progress,
    endings: const {},
    soundOn: false,
    onSoundChanged: (_) {},
    onSave: (_) {},
    onTitle: () {},
    onRestart: () {},
    onEnding: (kind) => ending = kind,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: onDevice
            ? Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(width: 1280, height: 720, child: room),
                ),
              )
            : room,
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('watch-button')));
  await tester.pump();
  await advanceDialogue(tester);
  tester.widget<ChoicePanel>(find.byType(ChoicePanel)).onChoose(0);
  await tester.pump();
  await advanceDialogue(tester);

  await tapHotspot(tester, 'calendar');
  await closePaper(tester);
  await tapHotspot(tester, 'blackboard');
  await advanceDialogue(tester);
  await closePaper(tester);
  await tapHotspot(tester, 'pillar');
  tester.widget<ChoicePanel>(find.byType(ChoicePanel)).onChoose(0);
  await tester.pump();
  await advanceDialogue(tester);

  await tester.tap(find.byKey(const Key('gear-hotspot')));
  await tester.pump();
  await advanceDialogue(tester);
  await tapHotspot(tester, 'tin');
  await advanceDialogue(tester);
  expect(progress.nicheRevealed, isTrue);

  await tester.tap(find.byKey(const Key('watch-button')));
  await tester.pump();
  await advanceDialogue(tester);
  expect(progress.era, Era.future);

  await tapHotspot(tester, 'drawer');
  await advanceDialogue(tester);
  await unlock(tester, [4, 1, 3]);
  await advanceDialogue(tester);
  await closePaper(tester);
  expect(progress.hasWindKey, isTrue);

  await tapHotspot(tester, 'niche');
  await advanceDialogue(tester);
  await closePaper(tester);
  expect(progress.hasGear, isTrue);

  await tester.tap(find.text('歯車'));
  await tester.pump();
  await tapHotspot(tester, 'clock');
  await advanceDialogue(tester);
  expect(progress.clockGearInstalled, isTrue);

  await tapHotspot(tester, 'clock');
  await advanceDialogue(tester);
  await unlock(tester, [1, 9, 2, 8]);
  await advanceDialogue(tester);
  await closePaper(tester);
  expect(progress.docs, contains('memo3'));

  await tapHotspot(tester, 'chair');
  await advanceDialogue(tester);
  await closePaper(tester);
  expect(progress.hasPendulum, isTrue);
  await tester.tap(find.text('振り子'));
  await tester.pump();
  await tapHotspot(tester, 'clock');
  await advanceDialogue(tester);
  expect(progress.clockPendulumInstalled, isTrue);
  await tester.tap(find.text('鍵'));
  await tester.pump();
  await tapHotspot(tester, 'clock');
  await advanceDialogue(tester);
  expect(progress.clockRunning, isTrue);

  await tapHotspot(tester, 'door');
  expect(find.byType(DoorDial), findsOneWidget);
  for (final glyph in encodeWord('またね')!) {
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
  expect(ending, 'normal');
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('最初から「またね」まで全謎を通れる', (tester) async {
    await runWalkthrough(tester);
  });
}
