import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_progress.dart';
import 'game_room.dart';
import 'widgets/ending_screen.dart';

const _saveKey = 'mio100.save.v2';
const _endingsKey = 'mio100.endings.v1';
const _soundKey = 'mio100.sound.v1';

enum _AppScreen { title, game, ending }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final preferences = await SharedPreferences.getInstance();
  runApp(MioApp(preferences: preferences));
}

class MioApp extends StatefulWidget {
  const MioApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  State<MioApp> createState() => _MioAppState();
}

class _MioAppState extends State<MioApp> {
  late GameProgress _progress;
  late Set<String> _endings;
  late bool _soundOn;
  _AppScreen _screen = _AppScreen.title;
  String? _endingKind;

  @override
  void initState() {
    super.initState();
    _progress = GameProgress.fromJson(
      widget.preferences.getString(_saveKey) ?? '',
    );
    _endings = widget.preferences.getStringList(_endingsKey)?.toSet() ?? {};
    _soundOn = widget.preferences.getBool(_soundKey) ?? true;
  }

  void _save(GameProgress progress) {
    unawaited(widget.preferences.setString(_saveKey, progress.toJson()));
  }

  void _start() {
    setState(() {
      _progress = GameProgress();
      _screen = _AppScreen.game;
    });
    _save(_progress);
  }

  void _completeEnding(String kind) {
    setState(() {
      _endings.add(kind);
      _endingKind = kind;
      _screen = _AppScreen.ending;
    });
    unawaited(widget.preferences.setStringList(_endingsKey, _endings.toList()));
    unawaited(widget.preferences.remove(_saveKey));
  }

  void _finishEnding() {
    setState(() {
      _progress = GameProgress();
      _screen = _AppScreen.title;
      _endingKind = null;
    });
  }

  void _setSound(bool enabled) {
    setState(() => _soundOn = enabled);
    unawaited(widget.preferences.setBool(_soundKey, enabled));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ミオと百年時計',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Scaffold(
        backgroundColor: Colors.black,
        // iPadOS no longer lets an app force landscape, so a tall window
        // asks to be turned instead of shrinking the room to a strip.
        body: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth < constraints.maxHeight
              ? const _RotateHint()
              : Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 1280,
                      height: 720,
                      child: switch (_screen) {
                        _AppScreen.game => GameRoom(
                          progress: _progress,
                          endings: _endings,
                          soundOn: _soundOn,
                          onSoundChanged: _setSound,
                          onSave: _save,
                          onTitle: () =>
                              setState(() => _screen = _AppScreen.title),
                          onRestart: _start,
                          onEnding: _completeEnding,
                        ),
                        _AppScreen.ending => EndingScreen(
                          key: ValueKey(_endingKind),
                          kind: _endingKind!,
                          soundOn: _soundOn,
                          onFinish: _finishEnding,
                        ),
                        _AppScreen.title => _TitleScreen(
                          hasSave: _progress.hasProgress,
                          endings: _endings,
                          onStart: _start,
                          onContinue: () =>
                              setState(() => _screen = _AppScreen.game),
                        ),
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _TitleScreen extends StatelessWidget {
  const _TitleScreen({
    required this.hasSave,
    required this.endings,
    required this.onStart,
    required this.onContinue,
  });

  final bool hasSave;
  final Set<String> endings;
  final VoidCallback onStart;
  final VoidCallback onContinue;

  VoidCallback? get _continueAction => hasSave ? onContinue : null;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/room_2126.png',
          fit: BoxFit.fill,
          errorBuilder: (_, error, stack) =>
              Container(color: const Color(0xFF10222C)),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xF0091625), Color(0xB0061728), Color(0x55030A11)],
              stops: [0, 0.53, 1],
            ),
          ),
        ),
        Positioned(
          left: 100,
          top: 90,
          width: 790,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ミオと\n百年時計',
                style: TextStyle(
                  color: Color(0xFFF3E6C8),
                  fontSize: 82,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black, blurRadius: 24)],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '― ときわけ書斎の約束 ―',
                style: TextStyle(
                  color: Color(0xFFD7C4A5),
                  fontSize: 27,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 46),
              _PlateButton(label: 'はじめから', onTap: onStart),
              const SizedBox(height: 14),
              _PlateButton(label: 'つづきから', onTap: _continueAction),
            ],
          ),
        ),
        Positioned(
          right: 34,
          bottom: 25,
          child: Row(
            children: [
              if (endings.contains('normal'))
                const Text(
                  '☾ またね  ',
                  style: TextStyle(color: Color(0xFFD7C4A5), fontSize: 19),
                ),
              const Text(
                'ESCAPE GAME',
                style: TextStyle(
                  color: Color(0xFFB5C6CD),
                  fontSize: 15,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlateButton extends StatelessWidget {
  const _PlateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: SizedBox(
            width: 368,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/ui_button_title.png',
                    fit: BoxFit.fill,
                    errorBuilder: (_, error, stack) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xCC4A2E1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8BF79)),
                      ),
                    ),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFF3E6C8),
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RotateHint extends StatelessWidget {
  const _RotateHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.screen_rotation, color: Color(0xFFE8BF79), size: 64),
          SizedBox(height: 18),
          Text(
            '端末を横向きにしてください',
            style: TextStyle(color: Color(0xFFF3E6C8), fontSize: 22),
          ),
        ],
      ),
    );
  }
}
