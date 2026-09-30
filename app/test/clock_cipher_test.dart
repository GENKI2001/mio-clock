import 'package:flutter_test/flutter_test.dart';
import 'package:mio_clock/puzzles/clock_cipher.dart';

void main() {
  test('メモ3と黒板の時計は仕様どおりの言葉になる', () {
    expect(decodeSequence(memoThreeGlyphs), 'いすのした');
    expect(decodeSequence(blackboardExampleGlyphs), 'おかえり');
  });

  test('終章の言葉を時計へ変換できる', () {
    expect(encodeWord('またね'), [
      const ClockGlyph(7, 1),
      const ClockGlyph(4, 1),
      const ClockGlyph(5, 4),
    ]);
    expect(decodeSequence(encodeWord('おかえり')!), 'おかえり');
  });

  test('使わない針と空欄は無効', () {
    expect(decodeClock(const ClockGlyph(11, 1)), isNull);
    expect(decodeClock(const ClockGlyph(1, 6)), isNull);
    expect(decodeClock(const ClockGlyph(8, 2)), isNull);
    expect(encodeKana('ん'), isNull);
  });
}
