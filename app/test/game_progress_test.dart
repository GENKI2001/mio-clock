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

  test('時代と謎の進行は保存して復元できる', () {
    final progress = GameProgress()
      ..travel()
      ..calendarSeen = true
      ..hintLevel = 2;
    final restored = GameProgress.fromJson(progress.toJson());
    expect(restored.era, Era.past);
    expect(restored.metMio, isTrue);
    expect(restored.calendarSeen, isTrue);
    expect(restored.hintLevel, 2);
  });
}
