import 'package:flutter/material.dart';

import '../data/story_text.dart';
import '../game_progress.dart';
import 'washi_card.dart';

/// The letters (and the old newspaper) gathered so far, to read again.
class LettersPanel extends StatelessWidget {
  const LettersPanel({
    super.key,
    required this.progress,
    required this.onDocument,
    required this.onClose,
  });

  static const order = ['memo1', 'memo2', 'memo3', 'memo4', 'newspaper'];
  static const _dates = {
    'memo1': '大正十五年 四月十三日',
    'memo2': '昭和二年 四月十三日',
    'memo3': '昭和三年 四月十三日',
    'memo4': '昭和五年 四月十三日',
    'newspaper': '昭和五年 四月十四日',
  };

  final GameProgress progress;
  final ValueChanged<String> onDocument;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final letters = [
      for (final id in order)
        if (progress.docs.contains(id)) id,
    ];
    return WashiCard(
      title: '手紙',
      onClose: onClose,
      child: letters.isEmpty
          ? const Center(
              child: Text(
                'まだ手紙はない。',
                style: TextStyle(color: washiInk, fontSize: 20),
              ),
            )
          : GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.74,
              children: [for (final id in letters) _letterCard(id)],
            ),
    );
  }

  Widget _letterCard(String id) {
    final thumb = id == 'newspaper'
        ? 'assets/images/scene_newspaper.jpg'
        : 'assets/images/letter_$id.jpg';
    return WashiRow(
      key: Key('letter-$id'),
      onTap: () => onDocument(id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                thumb,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, error, stack) =>
                    const ColoredBox(color: Color(0xFFEFE2C4)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            documentTitles[id] ?? id,
            maxLines: 2,
            style: const TextStyle(
              color: washiInk,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          Text(
            _dates[id] ?? '',
            style: const TextStyle(color: washiAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Hints, each unlocked by watching a short ad. What has been revealed stays
/// readable for free.
class HintPanel extends StatelessWidget {
  const HintPanel({
    super.key,
    required this.stage,
    required this.revealed,
    required this.loading,
    required this.message,
    required this.onWatch,
    required this.onClose,
  });

  static const _labels = ['ヒント 1', 'ヒント 2', '答え'];

  final String stage;
  final int revealed;
  final bool loading;
  final String? message;
  final VoidCallback onWatch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final hints = hintText[stage] ?? const <String>[];
    return WashiCard(
      title: 'ヒント',
      onClose: onClose,
      child: ListView(
        children: [
          for (var index = 0; index < 3 && index < hints.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: index < revealed
                  ? _revealed(index, hints[index])
                  : index == revealed
                  ? _next(index)
                  : _locked(index),
            ),
          if (message != null)
            Text(
              message!,
              style: const TextStyle(
                color: washiRed,
                fontSize: 16,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(int index, {bool dim = false}) => Container(
    width: 74,
    padding: const EdgeInsets.symmetric(vertical: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: dim ? const Color(0x338A5A36) : washiAccent,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _labels[index],
      style: TextStyle(
        color: dim ? washiAccent : const Color(0xFFFFF4E0),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _revealed(int index, String text) => WashiRow(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _badge(index),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: washiInk, fontSize: 18, height: 1.55),
          ),
        ),
      ],
    ),
  );

  Widget _next(int index) => WashiRow(
    key: const Key('hint-watch'),
    onTap: loading ? null : onWatch,
    tint: const Color(0xB3FFF6E6),
    border: washiAccent,
    child: Row(
      children: [
        _badge(index),
        const SizedBox(width: 14),
        Icon(
          loading ? Icons.hourglass_top : Icons.smart_display_outlined,
          color: washiAccent,
          size: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            loading
                ? '広告を読み込んでいます……'
                : index == 2
                ? '広告を見て、答えを見る'
                : '広告を見て、${_labels[index]}を見る',
            style: const TextStyle(
              color: washiInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!loading) const Icon(Icons.chevron_right, color: washiAccent),
      ],
    ),
  );

  Widget _locked(int index) => WashiRow(
    tint: const Color(0x26FFFFFF),
    border: const Color(0x338A5A36),
    child: Row(
      children: [
        _badge(index, dim: true),
        const SizedBox(width: 14),
        const Icon(Icons.lock_outline, color: Color(0x998A5A36), size: 22),
        const SizedBox(width: 10),
        const Text(
          '前のヒントを見ると選べます',
          style: TextStyle(color: Color(0x998A5A36), fontSize: 16),
        ),
      ],
    ),
  );
}

class MenuPanel extends StatelessWidget {
  const MenuPanel({
    super.key,
    required this.largeText,
    required this.soundOn,
    required this.confirmReset,
    required this.onToggleText,
    required this.onToggleSound,
    required this.onTitle,
    required this.onReset,
    required this.onClose,
  });

  final bool largeText;
  final bool soundOn;
  final bool confirmReset;
  final VoidCallback onToggleText;
  final VoidCallback onToggleSound;
  final VoidCallback onTitle;
  final VoidCallback onReset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    Widget setting(IconData icon, String label, Widget control) => WashiRow(
      child: Row(
        children: [
          Icon(icon, color: washiAccent, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: washiInk, fontSize: 19),
            ),
          ),
          control,
        ],
      ),
    );
    return WashiCard(
      title: 'メニュー',
      width: 700,
      height: 520,
      onClose: onClose,
      child: ListView(
        children: [
          setting(
            Icons.text_fields,
            '文字の大きさ',
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('標準')),
                ButtonSegment(value: true, label: Text('大')),
              ],
              selected: {largeText},
              showSelectedIcon: false,
              onSelectionChanged: (_) => onToggleText(),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? const Color(0xFFFFF4E0)
                      : washiInk,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? washiAccent
                      : Colors.transparent,
                ),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: washiAccent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          setting(
            soundOn ? Icons.volume_up : Icons.volume_off,
            '音と声',
            Switch(
              value: soundOn,
              onChanged: (_) => onToggleSound(),
              activeThumbColor: const Color(0xFFFFF4E0),
              activeTrackColor: washiAccent,
            ),
          ),
          const SizedBox(height: 22),
          WashiRow(
            onTap: onTitle,
            child: const Row(
              children: [
                Icon(Icons.home_outlined, color: washiAccent, size: 26),
                SizedBox(width: 14),
                Text(
                  'タイトルへ戻る',
                  style: TextStyle(color: washiInk, fontSize: 19),
                ),
                Spacer(),
                Icon(Icons.chevron_right, color: washiAccent),
              ],
            ),
          ),
          const SizedBox(height: 10),
          WashiRow(
            onTap: onReset,
            tint: confirmReset
                ? const Color(0x33A0473A)
                : const Color(0x73FFFFFF),
            border: const Color(0x99A0473A),
            child: Row(
              children: [
                const Icon(Icons.restart_alt, color: washiRed, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    confirmReset ? 'もう一度押すと、最初からになります' : '最初からやり直す',
                    style: const TextStyle(color: washiRed, fontSize: 19),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
