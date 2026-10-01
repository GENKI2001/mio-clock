import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/game_room.dart';
import 'package:mio_clock/widgets/dialogue_panel.dart';
import 'package:mio_clock/widgets/letter_panel.dart';
import 'package:mio_clock/widgets/paper_panel.dart';
import 'package:mio_clock/widgets/puzzle_panels.dart';
import 'package:mio_clock/widgets/scenes.dart';

Future<void> advanceDialogue(WidgetTester tester) async {
  for (var index = 0; index < 80; index++) {
    await tester.pump();
    if (find.byType(DialoguePanel).evaluate().isEmpty) return;
    await tester.tap(find.byType(DialoguePanel));
    await tester.pump();
  }
  throw StateError('Dialogue did not finish');
}

/// Steps back from any close-up or scene so the whole room is reachable.
Future<void> stepBack(WidgetTester tester) async {
  final back = find.byKey(const Key('step-back'));
  if (back.evaluate().isEmpty) return;
  await tester.tap(back);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> tapHotspot(WidgetTester tester, String id) async {
  await stepBack(tester);
  await tester.tap(find.byKey(Key('hotspot-$id')));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> travel(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('watch-button')));
  await tester.pump();
  await advanceDialogue(tester);
  // Let the scene cross-fade to the other era finish.
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> selectItem(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('item-$id')));
  await tester.pump();
}

Future<void> useOn(WidgetTester tester, String item, String hotspot) async {
  await stepBack(tester);
  await selectItem(tester, item);
  await tapHotspot(tester, hotspot);
  await advanceDialogue(tester);
}

Future<void> askMio(WidgetTester tester, String topic) async {
  await tapHotspot(tester, 'mio');
  final talk = tester.widget<ChoicePanel>(find.byType(ChoicePanel));
  talk.onChoose(talk.choices.indexOf(topic));
  await tester.pump();
  await advanceDialogue(tester);
}

Future<void> closePaper(WidgetTester tester) async {
  final letter = find.byType(LetterPanel);
  if (letter.evaluate().isNotEmpty) {
    tester.widget<LetterPanel>(letter).onClose();
  } else {
    tester.widget<PaperPanel>(find.byType(PaperPanel)).onClose();
  }
  await tester.pump();
}

/// Turns the wheels of whichever lock close-up is open.
Future<void> unlock(WidgetTester tester, List<int> code) async {
  final lock = tester.widget<LockScene>(find.byType(LockScene));
  for (final (index, value) in code.indexed) {
    for (var turn = 0; turn < value; turn++) {
      lock.onDigit(index, 1);
    }
  }
  // No button: the lock opens as soon as the right number lines up.
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

  // At first only the pocket watch answers.
  await tester.tap(find.byKey(const Key('hotspot-drawer')));
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byType(DialoguePanel), findsNothing);
  expect(find.byKey(const Key('step-back')), findsNothing);

  // Meet Mio in 1926: where from, which year, and what became of the house.
  await travel(tester);
  for (var answer = 0; answer < 3; answer++) {
    tester.widget<ChoicePanel>(find.byType(ChoicePanel)).onChoose(0);
    await tester.pump();
    await advanceDialogue(tester);
  }
  // Mio points at the big clock (the camera looks and returns) and sends
  // the player to check it.
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.pump(const Duration(milliseconds: 600));
  await advanceDialogue(tester);
  expect(progress.flag('tourStarted'), isTrue);

  // Only the watch answers now; in 2026 only the clock does.
  await tester.tap(find.byKey(const Key('hotspot-calendar')));
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byType(DialoguePanel), findsNothing);
  await travel(tester);
  await tester.tap(find.byKey(const Key('hotspot-drawer')));
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byType(DialoguePanel), findsNothing);
  await tapHotspot(tester, 'clock');
  await advanceDialogue(tester);
  expect(progress.flag('clockChecked'), isTrue);

  // Back in 1926 the camera finds Mio and the conversation picks up.
  await stepBack(tester);
  await travel(tester);
  await tester.pump(const Duration(milliseconds: 600));
  await advanceDialogue(tester);
  for (var answer = 0; answer < 2; answer++) {
    tester.widget<ChoicePanel>(find.byType(ChoicePanel)).onChoose(0);
    await tester.pump();
    await advanceDialogue(tester);
  }
  expect(progress.flag('tourDone'), isTrue);

  // Before the box's riddle, the pillar is only a pillar.
  await tapHotspot(tester, 'pillar');
  expect(find.byType(PillarScene), findsOneWidget);
  expect(find.byType(DialoguePanel), findsNothing);
  expect(progress.heightMarked, isFalse);

  // The calendar: 4/13.
  await tapHotspot(tester, 'calendar');
  expect(find.byType(CalendarScene), findsOneWidget);

  // The drawer lock in 2026.
  await stepBack(tester);
  await travel(tester);
  await tapHotspot(tester, 'drawer');
  await unlock(tester, [4, 1, 3]);
  await advanceDialogue(tester);
  await closePaper(tester);
  expect(progress.inventory, containsAll(['windKey', 'matches']));

  // The workbench from above in 1926: Mio seals the gear in her tin. The
  // see-through player carries nothing there.
  await travel(tester);
  expect(find.byKey(const Key('item-matches')), findsNothing);
  await tapHotspot(tester, 'workbench');
  expect(find.byType(WorkbenchScene), findsOneWidget);
  await tester.tap(find.byKey(const Key('scene-gear')));
  await tester.pump();
  await advanceDialogue(tester);
  await tester.tap(find.byKey(const Key('scene-tin')));
  await tester.pump();
  await advanceDialogue(tester);
  expect(progress.gearInTin, isTrue);

  // Jump while looking at the bench: the same tin, a hundred years on.
  await travel(tester);
  expect(find.byType(WorkbenchScene), findsOneWidget);
  await selectItem(tester, 'matches');
  await tester.tap(find.byKey(const Key('scene-tin')));
  await tester.pump();
  await advanceDialogue(tester);
  await closePaper(tester);
  expect(progress.inventory, contains('gear'));

  await useOn(tester, 'gear', 'clock');
  expect(progress.clockGearInstalled, isTrue);

  // The little box beside the blackboard asks for Mio's growth spurt.
  await tapHotspot(tester, 'shelfBox');
  await advanceDialogue(tester);
  expect(find.byType(LockScene), findsOneWidget);

  // Mio measures herself; the pillar remembers five birthdays.
  await travel(tester);
  // Mio asks where; finding the pillar is up to the player.
  await askMio(tester, '背を測ってほしい');
  expect(progress.heightMarked, isFalse);
  await tapHotspot(tester, 'pillar');
  await advanceDialogue(tester);
  expect(progress.heightMarked, isTrue);
  await stepBack(tester);
  await travel(tester);
  await tapHotspot(tester, 'pillar');
  expect(find.byType(PillarScene), findsOneWidget);
  await tapHotspot(tester, 'shelfBox');
  await advanceDialogue(tester);
  await unlock(tester, [1, 9, 2, 8]);
  await advanceDialogue(tester);
  expect(progress.inventory, containsAll(['driver', 'blankLetter']));

  // Light the fireplace and warm Mio's citrus-ink letter over it.
  await useOn(tester, 'matches', 'fireplace');
  expect(progress.fireLit, isTrue);
  expect(progress.inventory, isNot(contains('matches')), reason: '二回使い終えた');
  await useOn(tester, 'blankLetter', 'fireplace');
  await closePaper(tester);
  expect(progress.docs, contains('memo3'));

  // Mio's favourite place, and the floorboard under it.
  await stepBack(tester);
  await travel(tester);
  await askMio(tester, '好きな場所');
  await stepBack(tester);
  await travel(tester);
  await useOn(tester, 'driver', 'chair');
  await closePaper(tester);
  expect(progress.inventory, contains('pendulum'));
  await useOn(tester, 'pendulum', 'clock');
  expect(progress.clockPendulumInstalled, isTrue);

  // The rusted spring, and oil that keeps for a century.
  await useOn(tester, 'windKey', 'clock');
  expect(progress.flag('springRusty'), isTrue);
  expect(progress.clockRunning, isFalse);
  await stepBack(tester);
  await travel(tester);
  await askMio(tester, '錆びたぜんまい');
  expect(progress.flag('codeOnBoard'), isTrue);

  // Mio's chalk has not lasted a century; she scratches it into the glass.
  await stepBack(tester);
  await travel(tester);
  await tapHotspot(tester, 'blackboard');
  await advanceDialogue(tester);
  expect(progress.flag('boardFaded'), isTrue);
  await stepBack(tester);
  await travel(tester);
  await askMio(tester, '黒板の数字');
  await stepBack(tester);
  await travel(tester);
  await tapHotspot(tester, 'window');
  await advanceDialogue(tester);
  await tapHotspot(tester, 'clockBase');
  await advanceDialogue(tester);
  await unlock(tester, [2, 7, 5]);
  await advanceDialogue(tester);
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(BaseDrawerScene), findsOneWidget);
  await tester.tap(find.byKey(const Key('scene-oil')));
  await tester.pump();
  await advanceDialogue(tester);
  expect(progress.inventory, contains('oil'));
  await useOn(tester, 'oil', 'clock');
  await useOn(tester, 'windKey', 'clock');
  expect(progress.clockRunning, isTrue);

  // The door's recess has the shape of Mio's watch. Mio promises to hand
  // it down; the watch in the player's hand fits the door.
  await tapHotspot(tester, 'door');
  await advanceDialogue(tester);
  expect(find.byType(DoorScene), findsOneWidget);
  await stepBack(tester);
  await travel(tester);
  await askMio(tester, '扉のくぼみ');
  expect(progress.flag('watchPromised'), isTrue);
  await stepBack(tester);
  await travel(tester);
  await tapHotspot(tester, 'door');
  await advanceDialogue(tester);
  await tester.tap(find.byKey(const Key('watch-button')));
  await tester.pump();
  await advanceDialogue(tester);
  expect(ending, 'normal');
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('最初から扉が開くまで全謎を通れる', (tester) async {
    await runWalkthrough(tester);
  });
}
