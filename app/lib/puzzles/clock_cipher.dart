class ClockGlyph {
  const ClockGlyph(this.hour, this.minuteMark);

  final int hour;
  final int minuteMark;

  @override
  bool operator ==(Object other) =>
      other is ClockGlyph &&
      other.hour == hour &&
      other.minuteMark == minuteMark;

  @override
  int get hashCode => Object.hash(hour, minuteMark);
}

const _rows = <String>[
  'あいうえお',
  'かきくけこ',
  'さしすせそ',
  'たちつてと',
  'なにぬねの',
  'はひふへほ',
  'まみむめも',
  'や ゆ よ',
  'らりるれろ',
  'わ   を',
];

String? decodeClock(ClockGlyph glyph) {
  if (glyph.hour < 1 ||
      glyph.hour > 10 ||
      glyph.minuteMark < 1 ||
      glyph.minuteMark > 5) {
    return null;
  }
  final result = _rows[glyph.hour - 1][glyph.minuteMark - 1];
  return result == ' ' ? null : result;
}

ClockGlyph? encodeKana(String kana) {
  if (kana.length != 1) return null;
  for (var row = 0; row < _rows.length; row++) {
    final column = _rows[row].indexOf(kana);
    if (column >= 0) return ClockGlyph(row + 1, column + 1);
  }
  return null;
}

List<ClockGlyph>? encodeWord(String word) {
  final result = <ClockGlyph>[];
  for (final rune in word.runes) {
    final glyph = encodeKana(String.fromCharCode(rune));
    if (glyph == null) return null;
    result.add(glyph);
  }
  return result;
}

String decodeSequence(Iterable<ClockGlyph> glyphs) =>
    glyphs.map((glyph) => decodeClock(glyph) ?? '？').join();

const memoThreeGlyphs = <ClockGlyph>[
  ClockGlyph(1, 2),
  ClockGlyph(3, 3),
  ClockGlyph(5, 5),
  ClockGlyph(3, 2),
  ClockGlyph(4, 1),
];

const blackboardExampleGlyphs = <ClockGlyph>[
  ClockGlyph(1, 5),
  ClockGlyph(2, 1),
  ClockGlyph(1, 4),
  ClockGlyph(9, 2),
];
