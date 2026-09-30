import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../puzzles/clock_cipher.dart';
import 'clock_glyph.dart';

class DoorDial extends StatelessWidget {
  const DoorDial({
    super.key,
    required this.hour,
    required this.minuteMark,
    required this.shortHandActive,
    required this.glyphs,
    required this.message,
    required this.onSelectHand,
    required this.onSetNumber,
    required this.onStamp,
    required this.onErase,
    required this.onSay,
  });

  final int hour;
  final int minuteMark;
  final bool shortHandActive;
  final List<ClockGlyph> glyphs;
  final String? message;
  final ValueChanged<bool> onSelectHand;
  final ValueChanged<int> onSetNumber;
  final VoidCallback onStamp;
  final VoidCallback onErase;
  final VoidCallback onSay;

  @override
  Widget build(BuildContext context) {
    final current = ClockGlyph(hour, minuteMark);
    final preview = decodeClock(current) ?? '—';
    return SizedBox(
      width: 890,
      height: 475,
      child: Row(
        children: [
          SizedBox(
            width: 350,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _handButton('短針（行）', true),
                    const SizedBox(width: 10),
                    _handButton('長針（段）', false),
                  ],
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  key: const Key('door-clock-face'),
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _choose(details.localPosition),
                  onPanUpdate: (details) => _choose(details.localPosition),
                  child: ClockGlyphView(glyph: current, size: 300),
                ),
                const SizedBox(height: 12),
                Text(
                  '数字をタップ、または針をドラッグ',
                  style: TextStyle(
                    fontSize: 17,
                    color: const Color(0xFF3E2B1F).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '「約束の言葉を、時の針で」',
                  style: TextStyle(
                    color: Color(0xFF3E2B1F),
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'いまの時刻：$hour時${minuteMark * 5}分  →  $preview',
                  style: const TextStyle(
                    color: Color(0xFF815B39),
                    fontSize: 23,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '刻んだ言葉  ${glyphs.length} / 6',
                  style: const TextStyle(
                    color: Color(0xFF3E2B1F),
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 104,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E9),
                    border: Border.all(color: const Color(0xFFB59160)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final glyph in glyphs)
                        SizedBox(
                          width: 76,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClockGlyphView(glyph: glyph, size: 64),
                              Text(
                                decodeClock(glyph) ?? '？',
                                style: const TextStyle(
                                  color: Color(0xFF6A4329),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (glyphs.isEmpty)
                        const Center(
                          child: Text(
                            'まだ言葉は刻まれていない',
                            style: TextStyle(
                              color: Color(0xFF8D806F),
                              fontSize: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 19),
                if (message != null)
                  Text(
                    message!,
                    style: const TextStyle(
                      color: Color(0xFF9E4537),
                      fontSize: 18,
                    ),
                  )
                else
                  const SizedBox(height: 28),
                const Spacer(),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _actionButton('刻む', Icons.edit, onStamp),
                    _actionButton('ひとつ消す', Icons.backspace_outlined, onErase),
                    _actionButton(
                      '告げる',
                      Icons.record_voice_over,
                      onSay,
                      primary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _handButton(String label, bool short) {
    final selected = shortHandActive == short;
    return GestureDetector(
      onTap: () => onSelectHand(short),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7F5030) : const Color(0xFFDFCCA8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB59160)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFFFF2D7) : const Color(0xFF3E2B1F),
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          primary ? const Color(0xFF8C522F) : const Color(0xFFBCA17A),
        ),
        foregroundColor: const WidgetStatePropertyAll(Color(0xFFFFF2D7)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 18)),
      ),
    );
  }

  void _choose(Offset position) {
    final dx = position.dx - 150;
    final dy = position.dy - 150;
    if (math.sqrt(dx * dx + dy * dy) < 30) return;
    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final rounded = ((angle / (2 * math.pi) * 12).round()) % 12;
    onSetNumber(rounded == 0 ? 12 : rounded);
  }
}
