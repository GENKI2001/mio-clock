import 'dart:async';

import 'package:flutter/material.dart';

import '../data/story_text.dart';

class DialoguePanel extends StatefulWidget {
  const DialoguePanel({
    super.key,
    required this.line,
    required this.onNext,
    this.largeText = false,
  });

  final DialogueLine line;
  final VoidCallback onNext;
  final bool largeText;

  @override
  State<DialoguePanel> createState() => _DialoguePanelState();
}

class _DialoguePanelState extends State<DialoguePanel> {
  Timer? _timer;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant DialoguePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line) _start();
  }

  void _start() {
    _timer?.cancel();
    _shown = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        _shown++;
        if (_shown >= widget.line.text.length) {
          _shown = widget.line.text.length;
          timer.cancel();
        }
      });
    });
  }

  void _tap() {
    if (_shown < widget.line.text.length) {
      _timer?.cancel();
      setState(() => _shown = widget.line.text.length);
    } else {
      widget.onNext();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: Stack(
          children: [
            Container(color: Colors.black.withValues(alpha: 0.13)),
            Positioned(
              left: 425,
              right: 155,
              bottom: 22,
              child: Container(
                constraints: const BoxConstraints(minHeight: 135),
                padding: const EdgeInsets.fromLTRB(27, 17, 27, 17),
                decoration: BoxDecoration(
                  color: const Color(0xF0081B28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE8BF79),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.line.speaker != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          widget.line.speaker!,
                          style: const TextStyle(
                            color: Color(0xFFE8BF79),
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                          ),
                        ),
                      ),
                    Text(
                      widget.line.text.substring(0, _shown),
                      style: TextStyle(
                        color: const Color(0xFFF3E6C8),
                        fontSize: widget.largeText ? 25 : 21,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _shown == widget.line.text.length ? 'タップして進む  ▸' : '…',
                        style: const TextStyle(
                          color: Color(0xFFE8BF79),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
