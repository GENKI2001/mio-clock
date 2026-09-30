import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_progress.dart';
import 'game_room.dart';

const _saveKey = 'mio100.flutter.prototype.v1';

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
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _progress = GameProgress.fromJson(
      widget.preferences.getString(_saveKey) ?? '',
    );
  }

  void _save(GameProgress progress) {
    unawaited(widget.preferences.setString(_saveKey, progress.toJson()));
  }

  void _start() {
    setState(() {
      _progress = GameProgress();
      _playing = true;
    });
    _save(_progress);
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
              child: _playing
                  ? GameRoom(
                      progress: _progress,
                      onSave: _save,
                      onTitle: () => setState(() => _playing = false),
                    )
                  : _TitleScreen(
                      hasSave: _progress.hasProgress,
                      onStart: _start,
                      onContinue: () => setState(() => _playing = true),
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
    required this.onStart,
    required this.onContinue,
  });

  final bool hasSave;
  final VoidCallback onStart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/room_2126.png', fit: BoxFit.fill),
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
            ],
          ),
        ),
        const Positioned(
          right: 34,
          bottom: 25,
          child: Text(
            'FLUTTER PROTOTYPE  ·  謎1「カレンダーの丸」',
            style: TextStyle(
              color: Color(0xFFB5C6CD),
              fontSize: 15,
              letterSpacing: 2,
            ),
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
