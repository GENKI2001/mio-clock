import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_progress.dart';
import 'game_room.dart';
import 'widgets/ending_screen.dart';

const _saveKey = 'mio100.flutter.prototype.v1';
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

  void _doorShortcut() {
    setState(() {
      _progress = GameProgress.readyAtDoor();
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
        body: Center(
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
                  onTitle: () => setState(() => _screen = _AppScreen.title),
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
                  onContinue: () => setState(() => _screen = _AppScreen.game),
                  onDoor: _doorShortcut,
                ),
              },
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
    required this.onDoor,
  });

  final bool hasSave;
  final Set<String> endings;
  final VoidCallback onStart;
  final VoidCallback onContinue;
  final VoidCallback onDoor;

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
                '百年前の少女と、同じ部屋で謎を解く。',
                style: TextStyle(
                  color: Color(0xFFE8BF79),
                  fontSize: 22,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 50),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('はじめる'),
                    style: _buttonStyle(),
                  ),
                  if (hasSave) ...[
                    const SizedBox(width: 18),
                    OutlinedButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.history),
                      label: const Text('つづきから'),
                      style: _buttonStyle(),
                    ),
                  ],
                ],
              ),
              if (endings.isNotEmpty) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onDoor,
                  icon: const Icon(Icons.door_front_door_outlined),
                  label: const Text('扉の前から'),
                  style: _buttonStyle(),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 100,
          bottom: 25,
          child: const Text(
            '音あり推奨  ·  ヘッドホンで時の旋律を',
            style: TextStyle(
              color: Color(0xFFB5C6CD),
              fontSize: 16,
              letterSpacing: 2,
            ),
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
              if (endings.contains('true'))
                const Text(
                  '☀ おかえり  ',
                  style: TextStyle(color: Color(0xFFE8BF79), fontSize: 19),
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

  ButtonStyle _buttonStyle() => ButtonStyle(
    foregroundColor: const WidgetStatePropertyAll(Color(0xFFF3E6C8)),
    backgroundColor: const WidgetStatePropertyAll(Color(0xCC9E683C)),
    side: const WidgetStatePropertyAll(
      BorderSide(color: Color(0xFFE8BF79), width: 1.5),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 27, vertical: 17),
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    ),
  );
}
