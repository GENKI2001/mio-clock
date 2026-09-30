import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/game_room.dart';
import 'package:mio_clock/puzzles/clock_cipher.dart';
import 'package:mio_clock/widgets/door_dial.dart';

Future<String?> playDoorWord(WidgetTester tester, String word) async {
  String? ending;
  final progress = GameProgress.readyAtDoor();
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
          onEnding: (kind) => ending = kind,
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('hotspot-door')));
  await tester.pump();
  expect(find.byType(DoorDial), findsOneWidget);

  for (final glyph in encodeWord(word)!) {
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

  testWidgets('時計文字盤で「またね」を刻むとノーマルエンド', (tester) async {
    expect(await playDoorWord(tester, 'またね'), 'normal');
  });

  testWidgets('時計文字盤で「おかえり」を刻むとトゥルーエンド', (tester) async {
    expect(await playDoorWord(tester, 'おかえり'), 'true');
  });

  testWidgets('「さよなら」は特別な誤答となり入力は残る', (tester) async {
    expect(await playDoorWord(tester, 'さよなら'), isNull);
    expect(find.textContaining('ミオが、いちばん嫌っていた言葉だ'), findsOneWidget);
    expect(tester.widget<DoorDial>(find.byType(DoorDial)).glyphs.length, 4);
  });

  testWidgets('無効な時刻は文字として刻めない', (tester) async {
    final progress = GameProgress.readyAtDoor();
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
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('hotspot-door')));
    await tester.pump();
    var dial = tester.widget<DoorDial>(find.byType(DoorDial));
    dial.onSelectHand(true);
    dial.onSetNumber(11);
    dial.onSelectHand(false);
    dial.onSetNumber(6);
    await tester.pump();
    dial = tester.widget<DoorDial>(find.byType(DoorDial));
    dial.onStamp();
    await tester.pump();
    expect(find.text('その時刻は、言葉にならないようだ。'), findsOneWidget);
    expect(tester.widget<DoorDial>(find.byType(DoorDial)).glyphs, isEmpty);
  });

  testWidgets('文字盤の数字タップで短針と長針を操作できる', (tester) async {
    var hour = 12;
    var minute = 12;
    var shortHand = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DoorDial(
              hour: hour,
              minuteMark: minute,
              shortHandActive: shortHand,
              glyphs: const [],
              message: null,
              onSelectHand: (value) => shortHand = value,
              onSetNumber: (number) {
                if (shortHand) {
                  hour = number;
                } else {
                  minute = number;
                }
              },
              onStamp: () {},
              onErase: () {},
              onSay: () {},
            ),
          ),
        ),
      ),
    );
    final center = tester
        .getRect(find.byKey(const Key('door-clock-face')))
        .center;
    await tester.tapAt(center + const Offset(110, 0));
    expect(hour, 3);
    await tester.tap(find.text('長針（段）'));
    await tester.tapAt(center + const Offset(55, -95));
    expect(minute, 1);
  });

  testWidgets('ヒントの答えは確認を経て表示される', (tester) async {
    final progress = GameProgress.readyAtDoor();
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
          ),
        ),
      ),
    );
    await tester.tap(find.text('ヒント'));
    await tester.pump();
    expect(progress.hintLevel['s6'], 1);
    await tester.tap(find.text('もう一段階見る'));
    await tester.pump();
    expect(progress.hintLevel['s6'], 2);
    await tester.tap(find.text('もう一段階見る'));
    await tester.pump();
    expect(progress.hintLevel['s6'], 2);
    expect(find.text('次は答えを表示します。見ますか?'), findsOneWidget);
    await tester.tap(find.text('答えを見る'));
    await tester.pump();
    expect(progress.hintLevel['s6'], 3);
  });
}
