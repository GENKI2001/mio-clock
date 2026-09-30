import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/game_progress.dart';

void main() {
  test('謎1は未来の引き出しに413を入力したときだけ解ける', () {
    final progress = GameProgress();
    expect(progress.tryOpenDrawer([1, 2, 3]), isFalse);
    progress.travel();
    expect(progress.tryOpenDrawer([4, 1, 3]), isFalse);
    progress.travel();
    expect(progress.tryOpenDrawer([4, 1, 3]), isTrue);
    expect(progress.hasWindKey, isTrue);
  });

  test('歯車は時代を越えず、缶に隠したものだけ未来で取得できる', () {
    final progress = GameProgress()..travel();
    expect(progress.pickGear(), isTrue);
    progress.travel();
    expect(progress.holding1926, isFalse);
    expect(progress.gearSpot, GearSpot.workbench);
    expect(progress.collectGear(), isFalse);

    progress.travel();
    expect(progress.pickGear(), isTrue);
    expect(progress.placeGear(GearSpot.windowsill), isTrue);
    progress.travel();
    expect(progress.gearSpot, GearSpot.windowsill);
    expect(progress.collectGear(), isFalse);

    progress.travel();
    expect(progress.pickGear(), isTrue);
    expect(progress.placeGear(GearSpot.tin), isTrue);
    progress.travel();
    expect(progress.collectGear(), isTrue);
    expect(progress.hasGear, isTrue);
    expect(progress.installGear(), isTrue);
    expect(progress.hasGear, isFalse);
  });

  test('1928の錠、振り子、ねじ巻きは正しい順で進む', () {
    final progress = GameProgress(
      drawerOpened: true,
      inventory: {'gear', 'windKey'},
      docs: {'memo1'},
    );
    expect(progress.installGear(), isTrue);
    expect(progress.tryOpenBackPanel([1, 9, 2, 7]), isFalse);
    expect(progress.tryOpenBackPanel([1, 9, 2, 8]), isTrue);
    expect(progress.searchChair(), isFalse);
    progress.cipherLearned = true;
    expect(progress.searchChair(), isTrue);
    expect(progress.windClock(), isFalse);
    expect(progress.hasWindKey, isTrue);
    expect(progress.installPendulum(), isTrue);
    expect(progress.windClock(), isTrue);
    expect(progress.clockRunning, isTrue);
    expect(progress.currentStage({}), 's6');
    expect(progress.currentStage({'normal'}), 'sTrue');
  });

  test('時代・所持品・手帳・ヒントは保存して復元できる', () {
    final progress = GameProgress()
      ..travel()
      ..notes.add('n_calendar')
      ..hintLevel['s1'] = 2
      ..flags['gearTalk'] = true;
    final restored = GameProgress.fromJson(progress.toJson());
    expect(restored.era, Era.past);
    expect(restored.metMio, isTrue);
    expect(restored.notes, contains('n_calendar'));
    expect(restored.hintLevel['s1'], 2);
    expect(restored.flags['gearTalk'], isTrue);
  });

  test('旧試作版の保存データを読み込める', () {
    final restored = GameProgress.fromJson(
      '{"era":"future","drawerOpened":true,"calendarSeen":true,"hintLevel":2}',
    );
    expect(restored.hasWindKey, isTrue);
    expect(restored.notes, contains('n_calendar'));
    expect(restored.hintLevel['s1'], 2);
  });
}
