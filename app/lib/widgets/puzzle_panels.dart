import 'package:flutter/material.dart';

import '../data/story_text.dart';
import '../game_progress.dart';
import 'paper_panel.dart';

const _ink = Color(0xFF34291F);
const _red = Color(0xFF9B3F31);

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
    // A warm washi card in a light wooden frame; the text sits on its centre.
    // The painted frame has rounded corners with blank paper outside them,
    // so the card is clipped to the same curve and the shadow follows it.
    const corner = BorderRadius.all(Radius.circular(13));
    return Container(
      width: 780,
      height: 520,
      decoration: const BoxDecoration(
        borderRadius: corner,
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 36,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: corner,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/ui_frame_choice.jpg'),
              fit: BoxFit.fill,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(56, 40, 56, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _gilt,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '閉じる',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: _gilt, size: 26),
                  ),
                ],
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, _gilt, Colors.transparent],
                  ),
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: _cream,
                  fontSize: 21,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < choices.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ChoiceButton(
                            label: choices[index],
                            onTap: () => onChoose(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _gilt = Color(0xFF8A5A36);
const _cream = Color(0xFF3B2A1C);

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x66FFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: _gilt.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: _gilt.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              const Text(
                '◆',
                style: TextStyle(color: Color(0xFFD08A7E), fontSize: 14),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: _cream, fontSize: 21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
