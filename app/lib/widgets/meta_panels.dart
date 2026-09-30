import 'package:flutter/material.dart';

import '../data/story_text.dart';
import '../game_progress.dart';
import '../puzzles/clock_cipher.dart';
import 'clock_glyph.dart';
import 'paper_panel.dart';

const _ink = Color(0xFF34291F);

class NotebookPanel extends StatelessWidget {
  const NotebookPanel({
    super.key,
    required this.progress,
    required this.onDocument,
    required this.onClose,
  });

  final GameProgress progress;
  final ValueChanged<String> onDocument;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      title: '手帳',
      width: 865,
      onClose: onClose,
      child: SizedBox(
        height: 475,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: _ink,
                unselectedLabelColor: Color(0xFF8B765A),
                indicatorColor: Color(0xFF9B633B),
                labelStyle: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: 'メモ'),
                  Tab(text: '文書'),
                ],
              ),
              Expanded(child: TabBarView(children: [_notes(), _documents()])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notes() {
    if (progress.notes.isEmpty) {
      return const Center(child: Text('まだ記録はない。部屋を調べよう。'));
    }
    return ListView(
      children: [
        for (final id in progress.notes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: const BoxDecoration(
                color: Color(0xFFEBDBB8),
                border: Border(
                  left: BorderSide(color: Color(0xFFB88D59), width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noteText[id] ?? id,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 20,
                      height: 1.4,
                    ),
                  ),
                  if (id == 'n_cipher') ...[
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 14,
                      runSpacing: 5,
                      children: [
                        Text(
                          '1 あいうえお',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '2 かきくけこ',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '3 さしすせそ',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '4 たちつてと',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '5 なにぬねの',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '6 はひふへほ',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '7 まみむめも',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '8 や・ゆ・よ',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '9 らりるれろ',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                        Text(
                          '10 わ・・・を',
                          style: TextStyle(color: _ink, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                  if (id == 'n_example') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final glyph in blackboardExampleGlyphs)
                          Padding(
                            padding: const EdgeInsets.only(right: 13),
                            child: ClockGlyphView(glyph: glyph, size: 92),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _documents() {
    if (progress.docs.isEmpty) {
      return const Center(child: Text('まだ文書は見つかっていない。'));
    }
    return ListView(
      children: [
        for (final id in progress.docs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: OutlinedButton.icon(
              onPressed: () => onDocument(id),
              icon: const Icon(Icons.description_outlined),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(documentTitles[id] ?? id),
              ),
              style: ButtonStyle(
                foregroundColor: const WidgetStatePropertyAll(_ink),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: Color(0xFFB88D59)),
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 21),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                ),
              ),
            ),
          ),
      ],
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
