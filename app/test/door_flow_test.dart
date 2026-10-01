import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/game_room.dart';
import 'package:mio_clock/widgets/dialogue_panel.dart';
import 'package:mio_clock/widgets/puzzle_panels.dart';
import 'package:mio_clock/widgets/scenes.dart';

Widget room(GameProgress progress, {ValueChanged<String>? onEnding}) =>
    MaterialApp(
      home: Scaffold(
        body: GameRoom(
          progress: progress,
          endings: const {},
          soundOn: false,
          onSoundChanged: (_) {},
          onSave: (_) {},
          onTitle: () {},
          onRestart: () {},
          onEnding: onEnding ?? (_) {},
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
  throw StateError('Dialogue did not finish');
}

/// Opens the door close-up in the finished room and fits the watch with the
/// button in the corner.
Future<String?> playDoor(WidgetTester tester) async {
  String? ending;
  await tester.pumpWidget(
    room(GameProgress.readyAtDoor(), onEnding: (kind) => ending = kind),
  );
  await tester.tap(find.byKey(const Key('hotspot-door')));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 400));
  await advanceDialogue(tester);
  expect(find.byType(DoorScene), findsOneWidget);
  await tester.tap(find.byKey(const Key('watch-button')));
  await tester.pump();
  await advanceDialogue(tester);
  return ending;
}

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

  testWidgets('懐中時計をはめると、選択肢なしで結末へ進む', (tester) async {
    expect(await playDoor(tester), 'normal');
    expect(find.byType(ChoicePanel), findsNothing);
  });

  testWidgets('ミオの約束の前は、扉の前で懐中時計を押すと時代を移るだけ', (tester) async {
    final progress = GameProgress.readyAtDoor()..flags.remove('watchPromised');
    await tester.pumpWidget(room(progress));
    await tester.tap(find.byKey(const Key('hotspot-door')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    await advanceDialogue(tester);
    await tester.tap(find.byKey(const Key('watch-button')));
    await tester.pump();
    await advanceDialogue(tester);
    expect(progress.era, Era.past);
    expect(progress.flag('watchInserted'), isFalse);
  });

  testWidgets('1926年のミオに扉のくぼみを話すと、懐中時計を受け継ぐと約束する', (tester) async {
    final progress = GameProgress.readyAtDoor()
      ..era = Era.past
      ..flags.remove('watchPromised');
    await tester.pumpWidget(room(progress));
    await tester.tap(find.byKey(const Key('hotspot-mio')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    final talk = tester.widget<ChoicePanel>(find.byType(ChoicePanel));
    talk.onChoose(talk.choices.indexOf('扉のくぼみ'));
    await tester.pump();
    await advanceDialogue(tester);
    expect(progress.flag('watchPromised'), isTrue);
  });

  testWidgets('ヒントは広告を見るたびに一段ずつ開き、見なければ開かない', (tester) async {
    final progress = GameProgress.readyAtDoor();
    var watched = true;
    var ads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameRoom(
            progress: progress,
            endings: const {},
            soundOn: false,
            onSoundChanged: (_) {},
            onSave: (_) {},
            onTitle: () {},
            onRestart: () {},
            onEnding: (_) {},
            rewardGate: () async {
              ads++;
              return watched;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('ヒント'));
    await tester.pump();
    expect(progress.hintLevel['s6'] ?? 0, 0, reason: '開いただけでは見えない');
    for (var level = 1; level <= 3; level++) {
      await tester.tap(find.byKey(const Key('hint-watch')));
      await tester.pumpAndSettle();
      expect(progress.hintLevel['s6'], level);
    }
    expect(find.byKey(const Key('hint-watch')), findsNothing);
    expect(ads, 3);

    progress.hintLevel.clear();
    watched = false;
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();
    await tester.tap(find.text('ヒント'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('hint-watch')));
    await tester.pumpAndSettle();
    expect(progress.hintLevel['s6'] ?? 0, 0);
    expect(find.textContaining('ヒントは開きませんでした'), findsOneWidget);
  });
}
