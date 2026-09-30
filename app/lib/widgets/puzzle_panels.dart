import 'package:flutter/material.dart';

import '../data/story_text.dart';
import '../game_progress.dart';
import '../puzzles/clock_cipher.dart';
import 'clock_glyph.dart';
import 'paper_panel.dart';

const _ink = Color(0xFF34291F);
const _red = Color(0xFF9B3F31);

class CalendarPanel extends StatelessWidget {
  const CalendarPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(1926, 4, 1).weekday % 7;
    return PaperPanel(
      title: '大正十五年 四月',
      width: 735,
      onClose: onClose,
      child: Column(
        children: [
          const Text('ミオの部屋のカレンダー', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 18),
          SizedBox(
            height: 272,
            width: 520,
            child: Column(
              children: [
                Row(
                  children: [
                    for (final day in ['日', '月', '火', '水', '木', '金', '土'])
                      Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(color: _ink, fontSize: 19),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 7,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: List.generate(35, (index) {
                      final day = index - firstDay + 1;
                      if (day < 1 || day > 30) return const SizedBox();
                      return Center(
                        child: Container(
                          width: 44,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: day == 13
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _red, width: 3),
                                )
                              : null,
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              color: day == 13 ? _red : _ink,
                              fontSize: 22,
                              fontWeight: day == 13
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '13日に赤い丸。「ミオ 誕生日!」',
            style: TextStyle(
              color: _red,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class NumberLockPanel extends StatelessWidget {
  const NumberLockPanel({
    super.key,
    required this.title,
    required this.inscription,
    required this.digits,
    required this.error,
    required this.onDigit,
    required this.onOpen,
    required this.onClose,
  });

  final String title;
  final String inscription;
  final List<int> digits;
  final String? error;
  final void Function(int index, int delta) onDigit;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      title: title,
      width: digits.length == 4 ? 720 : 630,
      onClose: onClose,
      child: Column(
        children: [
          Text(
            inscription,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(digits.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Column(
                  children: [
                    IconButton(
                      key: Key('dial-$index-up'),
                      onPressed: () => onDigit(index, 1),
                      icon: const Icon(
                        Icons.keyboard_arrow_up,
                        color: _ink,
                        size: 40,
                      ),
                    ),
                    Container(
                      width: 75,
                      height: 82,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF46301E),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: const Color(0xFFC99E5C),
                          width: 3,
                        ),
                      ),
                      child: Text(
                        digits[index].toString(),
                        style: const TextStyle(
                          color: Color(0xFFFFF3D7),
                          fontSize: 50,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: Key('dial-$index-down'),
                      onPressed: () => onDigit(index, -1),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: _ink,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(
            height: 42,
            child: Center(
              child: Text(
                error ?? '',
                style: const TextStyle(color: _red, fontSize: 20),
              ),
            ),
          ),
          FilledButton.icon(
            key: const Key('unlock-button'),
            onPressed: onOpen,
            icon: const Icon(Icons.lock_open),
            label: const Text('開ける'),
            style: parchmentButton(primary: true),
          ),
        ],
      ),
    );
  }
}

class HeightMarksPanel extends StatelessWidget {
  const HeightMarksPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    const marks = [
      ('大正十五', '一四二', '1926', '+0'),
      ('昭和二', '一四五', '1927', '+3'),
      ('昭和三', '一五一', '1928', '+6'),
      ('昭和四', '一五三', '1929', '+2'),
      ('昭和五', '一五四', '1930', '+1'),
    ];
    return PaperPanel(
      title: '背比べの柱',
      width: 770,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('柱に、五本の印が刻まれている。下から順に――'),
          const SizedBox(height: 18),
          for (final mark in marks)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE1CBA4),
                borderRadius: BorderRadius.circular(7),
                border: Border(
                  left: BorderSide(
                    color: _ink.withValues(alpha: 0.6),
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.horizontal_rule, color: _ink),
                  const SizedBox(width: 14),
                  Text(
                    mark.$1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    mark.$2,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 9),
          const Text(
            'いちばん上の印の横に、小さな彫り文字。「つづきは みらいで」',
            style: TextStyle(color: _red, fontSize: 21),
          ),
        ],
      ),
    );
  }
}

class BlackboardPanel extends StatelessWidget {
  const BlackboardPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      title: 'ミオ式 時計暗号',
      width: 930,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'みじかい針 → 行',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const Text('1あ  2か  3さ  4た  5な  6は  7ま  8や  9ら  10わ'),
          const SizedBox(height: 13),
          const Text(
            'ながい針 → 段',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const Text('針が指す数字: 1あ  2い  3う  4え  5お'),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFF172E28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'れい',
                  style: TextStyle(color: Color(0xFFF3E6C8), fontSize: 24),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final glyph in blackboardExampleGlyphs)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        child: ClockGlyphView(glyph: glyph, size: 120),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'わたしの いちばん すきな ことば',
                  style: TextStyle(color: Color(0xFFF3E6C8), fontSize: 21),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentPanel extends StatelessWidget {
  const DocumentPanel({
    super.key,
    required this.id,
    required this.progress,
    required this.onClose,
  });

  final String id;
  final GameProgress progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      title: documentTitles[id] ?? '文書',
      width: id == 'newspaper' ? 900 : 825,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            documentText(id, progress),
            style: TextStyle(
              color: _ink,
              fontSize: id == 'newspaper' ? 20 : 21,
              height: 1.55,
            ),
          ),
          if (id == 'memo3') ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final glyph in memoThreeGlyphs)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: ClockGlyphView(glyph: glyph, size: 110),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              '昭和三年 四月十三日  ミオ',
              style: TextStyle(color: _ink, fontSize: 21),
            ),
          ],
        ],
      ),
    );
  }
}

class ClockBasePanel extends StatelessWidget {
  const ClockBasePanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      title: '大時計の台座',
      width: 720,
      onClose: onClose,
      child: Column(
        children: [
          const Text('台座に、小さな時計の絵が四つ彫られている。'),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final glyph in blackboardExampleGlyphs)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClockGlyphView(glyph: glyph, size: 125),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('……黒板の「れい」と同じだ。'),
        ],
      ),
    );
  }
}

class ChoicePanel extends StatelessWidget {
  const ChoicePanel({
    super.key,
    required this.title,
    required this.description,
    required this.choices,
    required this.onChoose,
    required this.onClose,
  });

  final String title;
  final String description;
  final List<String> choices;
  final ValueChanged<int> onChoose;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      title: title,
      width: 720,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(description),
          const SizedBox(height: 20),
          for (var index = 0; index < choices.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: FilledButton(
                onPressed: () => onChoose(index),
                style: parchmentButton(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(choices[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
