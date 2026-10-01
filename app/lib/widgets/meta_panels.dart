import 'package:flutter/material.dart';

import '../data/story_text.dart';
import '../game_progress.dart';
import 'paper_panel.dart';

const _ink = Color(0xFF34291F);

/// The letters (and the old newspaper) gathered so far, to read again.
class LettersPanel extends StatelessWidget {
  const LettersPanel({
    super.key,
    required this.progress,
    required this.onDocument,
    required this.onClose,
  });

  static const order = ['memo1', 'memo2', 'memo3', 'memo4', 'newspaper'];

  final GameProgress progress;
  final ValueChanged<String> onDocument;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final letters = [
      for (final id in order)
        if (progress.docs.contains(id)) id,
    ];
    return PaperPanel(
      title: '手紙',
      width: 640,
      onClose: onClose,
      child: letters.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('まだ手紙はない。'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final id in letters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton(
                      onPressed: () => onDocument(id),
                      style: parchmentButton(),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(documentTitles[id] ?? id),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class HintPanel extends StatelessWidget {
  const HintPanel({
    super.key,
    required this.stage,
    required this.level,
    required this.confirmAnswer,
    required this.past,
    required this.onMore,
    required this.onClose,
  });

  final String stage;
  final int level;
  final bool confirmAnswer;
  final bool past;
  final VoidCallback onMore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final hints = hintText[stage] ?? const <String>[];
    return PaperPanel(
      title: past ? 'ミオのヒント' : 'ミオの声を思い出す',
      width: 800,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < level && index < hints.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: index == level - 1
                      ? const Color(0xFFE9D3A9)
                      : const Color(0xFFF8EDD6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}. ${hints[index]}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 21,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          if (confirmAnswer)
            const Padding(
              padding: EdgeInsets.only(bottom: 13),
              child: Text(
                '次は答えを表示します。見ますか?',
                style: TextStyle(
                  color: Color(0xFF9B3F31),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (level < 3)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onMore,
                style: parchmentButton(primary: confirmAnswer),
                child: Text(confirmAnswer ? '答えを見る' : 'もう一段階見る'),
              ),
            ),
        ],
      ),
    );
  }
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
    return PaperPanel(
      title: '設定',
      width: 710,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onToggleText,
            icon: const Icon(Icons.text_fields),
            label: Text('文字サイズ: ${largeText ? '大' : '標準'}'),
            style: parchmentButton(),
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: onToggleSound,
            icon: Icon(soundOn ? Icons.volume_up : Icons.volume_off),
            label: Text('音: ${soundOn ? 'あり' : 'なし'}'),
            style: parchmentButton(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onTitle,
            icon: const Icon(Icons.home_outlined),
            label: const Text('タイトルへ戻る'),
            style: parchmentButton(),
          ),
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt),
            label: Text(confirmReset ? '本当に最初からやり直す' : '最初からやり直す'),
            style: ButtonStyle(
              foregroundColor: const WidgetStatePropertyAll(Color(0xFF9B3F31)),
              textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 20)),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
