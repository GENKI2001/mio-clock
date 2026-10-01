import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/game_progress.dart';

void main() {
  test('引き出しは2026年に413を入力したときだけ開き、鍵とマッチが手に入る', () {
    final progress = GameProgress();
    expect(progress.tryOpenDrawer([1, 2, 3]), isFalse);
    progress.travel();
    expect(progress.tryOpenDrawer([4, 1, 3]), isFalse);
    progress.travel();
    expect(progress.tryOpenDrawer([4, 1, 3]), isTrue);
    expect(progress.inventory, containsAll(['windKey', 'matches']));
  });

  test('歯車はミオが缶に封じたときだけ2026年に届き、マッチで蝋を溶かして取り出す', () {
    final progress = GameProgress();
    expect(progress.sealGearInTin(), isFalse);
    progress.travel();
    expect(progress.sealGearInTin(), isTrue);
    progress.travel();
    expect(progress.openTin(), isFalse);
    progress.inventory.add('matches');
    expect(progress.openTin(), isTrue);
    expect(progress.inventory, contains('gear'));
    expect(progress.installGear(), isTrue);
    expect(progress.inventory, isNot(contains('gear')));
  });

  test('柱の印、背面の錠、椅子の下、時計油、ねじ巻きの順に進む', () {
    final progress = GameProgress(
      drawerOpened: true,
      inventory: {'gear', 'windKey'},
      docs: {'memo1'},
    );
    expect(progress.installGear(), isTrue);
    expect(progress.tryOpenBox([1, 9, 2, 7]), isFalse);
    expect(progress.tryOpenBox([1, 9, 2, 8]), isTrue);
    expect(progress.inventory, contains('driver'));
    expect(progress.searchChair(), isFalse, reason: '手紙をあぶるまでは場所がわからない');
    expect(progress.revealLetter(), isFalse, reason: '火がない');
    progress.inventory.add('matches');
    expect(progress.lightFire(), isTrue);
    expect(progress.revealLetter(), isTrue);
    expect(progress.searchChair(), isTrue);
    expect(progress.inventory, isNot(contains('driver')));
    expect(progress.installPendulum(), isTrue);
    expect(progress.windClock(), isFalse, reason: 'ぜんまいが錆びている');

    progress.travel();
    expect(progress.hideOil(), isFalse, reason: '錆びた話を聞くまでは動かない');
    progress.flags['springRusty'] = true;
    expect(progress.hideOil(), isTrue);
    progress.travel();
    expect(progress.takeOil(), isFalse, reason: '台座の錠がかかっている');
    expect(progress.tryOpenBase([2, 7, 4]), isFalse);
    expect(progress.tryOpenBase([2, 7, 5]), isTrue);
    expect(progress.takeOil(), isTrue);
    expect(progress.oilClock(), isTrue);
    expect(progress.windClock(), isTrue);
    expect(progress.clockRunning, isTrue);
    expect(progress.currentStage({}), 's6');
  });

  test('背比べはミオが1926年に刻む', () {
    final progress = GameProgress();
    expect(progress.markHeight(), isFalse);
    progress.travel();
    expect(progress.markHeight(), isTrue);
    expect(progress.markHeight(), isFalse);
  });

  test('時代・所持品・手帳・ヒントは保存して復元できる', () {
    final progress = GameProgress()
      ..travel()
      ..gearInTin = true
      ..inventory.add('matches')
      ..notes.add('n_calendar')
      ..hintLevel['s1'] = 2
      ..flags['gearSeen'] = true;
    final restored = GameProgress.fromJson(progress.toJson());
    expect(restored.era, Era.past);
    expect(restored.metMio, isTrue);
    expect(restored.gearInTin, isTrue);
    expect(restored.inventory, contains('matches'));
    expect(restored.notes, contains('n_calendar'));
    expect(restored.hintLevel['s1'], 2);
    expect(restored.flag('gearSeen'), isTrue);
  });

  test('壊れた保存データは最初からになる', () {
    expect(GameProgress.fromJson('not json').hasProgress, isFalse);
  });
}
