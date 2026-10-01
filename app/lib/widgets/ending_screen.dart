import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/mio_voice.dart';
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
  final AudioPlayer _voice = AudioPlayer();
  Timer? _voiceDelay;
  int _index = 0;

  List<DialogueLine> get _lines => normalEndingLines;

  /// Mio keeps the face of her most recent line.
  String get _mioSprite {
    var expression = 'normal';
    for (var index = 0; index <= _index && index < _lines.length; index++) {
      if (_lines[index].speaker == 'ミオ') {
        expression = _lines[index].expression ?? 'normal';
      }
    }
    return switch (expression) {
      'smile' => 'assets/images/mio_14_smile.png',
      'surprise' => 'assets/images/mio_14_surprise.png',
      'embarrassed' => 'assets/images/mio_14_embarrassed.png',
      'proud' => 'assets/images/mio_14_proud.png',
      'sad' => 'assets/images/mio_14_sad.png',
      _ => 'assets/images/mio_14.png',
    };
  }

  bool get _finished => _index >= _lines.length;

  @override
  void initState() {
    super.initState();
    if (widget.soundOn) unawaited(_startAudio());
    _speak();
  }

  /// Mio's line, a breath after it appears.
  void _speak() {
    _voiceDelay?.cancel();
    unawaited(_voice.stop().catchError((_) {}));
    if (!widget.soundOn || _finished) return;
    final line = _lines[_index];
    final id = line.speaker == 'ミオ' ? mioVoice[line.text] : null;
    if (id == null) return;
    _voiceDelay = Timer(const Duration(milliseconds: 280), () {
      unawaited(
        _voice.play(AssetSource('voice/$id.m4a'), volume: 1).catchError((_) {}),
      );
    });
  }

  Future<void> _startAudio() async {
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('audio/bgm_2126.wav'), volume: 0.26);
    } catch (_) {
      // The ending remains playable when audio is unavailable.
    }
  }

  @override
  void dispose() {
    _voiceDelay?.cancel();
    unawaited(_music.dispose());
    unawaited(_voice.dispose());
    super.dispose();
  }

  void _advance() {
    if (_index < _lines.length) {
      setState(() => _index++);
      _speak();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The reunion plays out in the room; the last line opens on the picture
    // of the two of them walking out into the city.
    final background = _index >= _lines.length - 1
        ? 'assets/images/cg_true_epilogue.png'
        : 'assets/images/room_2126.png';
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
          // Darken only while text is shown; the last picture stays clear.
          AnimatedOpacity(
            opacity: _finished ? 0 : 1,
            duration: const Duration(milliseconds: 800),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66030C16),
                    Colors.transparent,
                    Color(0xD906111A),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
          ),
          // Mio, come through the years, standing in the middle of the room
          // while the two of them talk.
          if (_index >= 2 && _index < _lines.length - 1)
            Positioned(
              left: 640 - 160,
              top: 90,
              width: 320,
              height: 480,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Image.asset(
                  _mioSprite,
                  key: ValueKey(_mioSprite),
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => const SizedBox.shrink(),
                ),
              ),
            ),
          if (!_finished)
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
            )
          else
            // A small card tucked into the corner, so the picture is seen.
            Positioned(
              right: 28,
              bottom: 26,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                decoration: BoxDecoration(
                  color: const Color(0xC8091B26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x99E8BF79)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TRUE END',
                      style: TextStyle(
                        color: Color(0xFFFFF1D5),
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: widget.onFinish,
                      icon: const Icon(Icons.home_outlined, size: 20),
                      label: const Text('タイトルへ戻る'),
                      style: const ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(
                          Color(0xFFFFF1D5),
                        ),
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(fontSize: 18),
                        ),
                      ),
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
