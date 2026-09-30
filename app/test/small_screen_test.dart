import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/game_progress.dart';
import 'package:mio_clock/game_room.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('幅667相当で小さな缶と隠し棚をタップできる', (tester) async {
    tester.view.physicalSize = const Size(667, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final past = GameProgress(
      era: Era.past,
      introSeen: true,
      metMio: true,
      holding1926: true,
    );
    await tester.pumpWidget(scaledRoom(past));
    final tinSize = tester.getSize(find.byKey(const Key('hotspot-tin')));
    expect(tinSize.width, greaterThanOrEqualTo(90));
    await tester.tap(find.byKey(const Key('hotspot-tin')));
    await tester.pump();
    expect(past.nicheRevealed, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final future = GameProgress(
      era: Era.future,
      introSeen: true,
      metMio: true,
      gearSpot: GearSpot.tin,
      nicheRevealed: true,
    );
    await tester.pumpWidget(scaledRoom(future));
    await tester.tap(find.byKey(const Key('hotspot-niche')));
    await tester.pump();
    expect(future.tinOpened2126, isTrue);
    expect(tester.takeException(), isNull);
  });
}
