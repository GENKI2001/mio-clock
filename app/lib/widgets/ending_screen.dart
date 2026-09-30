import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/story_text.dart';

class EndingScreen extends StatefulWidget {
  const EndingScreen({
    super.key,
    required this.kind,
    required this.soundOn,
    required this.onFinish,
  });

  final String kind;
  final bool soundOn;
  final VoidCallback onFinish;

  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen> {
  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _chime = AudioPlayer();
  int _index = 0;

  bool get _trueEnding => widget.kind == 'true';
  List<DialogueLine> get _lines =>
      _trueEnding ? trueEndingLines : normalEndingLines;

  @override
  void initState() {
    super.initState();
    if (widget.soundOn) unawaited(_startAudio());
  }

  Future<void> _startAudio() async {
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(
        AssetSource(_trueEnding ? 'audio/bgm_true.wav' : 'audio/bgm_2126.wav'),
        volume: _trueEnding ? 0.42 : 0.26,
      );
      if (_trueEnding && mounted) {
        await _chime.play(AssetSource('audio/jingle_chime.wav'), volume: 0.72);
      }
    } catch (_) {
      // The ending remains playable when audio is unavailable.
    }
  }

  @override
  void dispose() {
    unawaited(_music.dispose());
    unawaited(_chime.dispose());
    super.dispose();
  }

  void _advance() {
    if (_index < _lines.length) setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final background = _trueEnding
        ? (_index >= _lines.length
              ? 'assets/images/cg_true_epilogue.png'
              : 'assets/images/room_dawn.png')
        : (_index >= 3
              ? 'assets/images/cg_normal.png'
              : 'assets/images/room_2126.png');
    var adultSprite = 'assets/images/mio_18.png';
    for (var index = 0; index <= _index && index < _lines.length; index++) {
      if (_lines[index].expression == 'adult_normal') {
        adultSprite = 'assets/images/mio_18_normal.png';
      } else if (_lines[index].expression == 'adult_cry') {
        adultSprite = 'assets/images/mio_18.png';
      }
    }
    return GestureDetector(
      onTap: _advance,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 650),
            child: Image.asset(
              background,
              key: ValueKey(background),
              fit: BoxFit.fill,
              errorBuilder: (_, error, stack) =>
                  Container(color: const Color(0xFF10222C)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _trueEnding
                    ? const [
                        Color(0x33050E18),
                        Colors.transparent,
                        Color(0xC90A1820),
                      ]
                    : const [
                        Color(0xAA030C16),
                        Color(0x6605111B),
                        Color(0xED06111A),
                      ],
              ),
            ),
          ),
          if (_trueEnding && _index >= 2 && _index < _lines.length)
            Positioned(
              right: 155,
              bottom: 93,
              width: 275,
              height: 590,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Image.asset(
                  adultSprite,
                  key: ValueKey(adultSprite),
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => const SizedBox(),
                ),
              ),
            ),
          if (_index < _lines.length) ...[
            Positioned(
              left: 45,
              top: 28,
              child: Text(
                _trueEnding ? '百年ぶりの夜明け' : '百年後の夜',
                style: const TextStyle(
                  color: Color(0xFFEACB91),
                  fontSize: 24,
                  letterSpacing: 4,
                ),
              ),
            ),
            Positioned(
              left: 130,
              right: 130,
              bottom: 35,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  key: ValueKey(_index),
                  constraints: const BoxConstraints(minHeight: 146),
                  padding: const EdgeInsets.fromLTRB(29, 19, 29, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xE8081C29),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFFE8BF79),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 18),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_lines[_index].speaker != null)
                        Text(
                          _lines[_index].speaker!,
                          style: const TextStyle(
                            color: Color(0xFFE8BF79),
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      Text(
                        _lines[_index].text,
                        style: const TextStyle(
                          color: Color(0xFFF7EBD4),
                          fontSize: 23,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_index + 1} / ${_lines.length}  タップして進む ▸',
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
            ),
          ] else
            Center(
              child: Container(
                width: 900,
                padding: const EdgeInsets.all(44),
                decoration: BoxDecoration(
                  color: const Color(0xE6091B26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8BF79), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 30),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _trueEnding ? 'TRUE END' : 'NORMAL END',
                      style: const TextStyle(
                        color: Color(0xFFE8BF79),
                        fontSize: 25,
                        letterSpacing: 7,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _trueEnding ? 'おかえり、百年ぶりのミオ' : 'またね、の約束',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFF1D5),
                        fontSize: 43,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _trueEnding
                          ? '百年前に止まった約束が、いま動き出した。'
                          : '扉は開いた。まだ「もっと正解」の言葉があるのかもしれない。',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE2D0B1),
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: widget.onFinish,
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('タイトルへ戻る'),
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Color(0xFF956039),
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          Color(0xFFFFF1D5),
                        ),
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        ),
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ミオと百年時計  ·  企画・物語・アート・実装',
                      style: TextStyle(color: Color(0xFFBBA987), fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
