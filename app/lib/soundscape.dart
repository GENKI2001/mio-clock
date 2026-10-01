import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'game_progress.dart';

class Soundscape {
  final AudioPlayer _past = AudioPlayer();
  final AudioPlayer _future = AudioPlayer();
  final AudioPlayer _effects = AudioPlayer();
  final AudioPlayer _tick = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  Timer? _fadeTimer;
  Timer? _tickTimer;
  Timer? _whisperTimer;
  Timer? _voiceDelay;
  final Random _random = Random();
  Era _era = Era.future;
  bool _enabled = true;
  bool _started = false;
  bool _clockRunning = false;
  double _pastVolume = 0;
  double _futureVolume = 0;

  Future<void> start(Era era, {bool clockRunning = false}) async {
    _era = era;
    _clockRunning = clockRunning;
    if (_started || !_enabled) return;
    try {
      await Future.wait([
        _past.setReleaseMode(ReleaseMode.loop),
        _future.setReleaseMode(ReleaseMode.loop),
      ]);
      await Future.wait([
        _past.setSource(AssetSource('audio/bgm_1926.wav')),
        _future.setSource(AssetSource('audio/bgm_2126.wav')),
      ]);
      await _past.setVolume(0);
      await _future.setVolume(0);
      await Future.wait([_past.resume(), _future.resume()]);
      _started = true;
      setEra(_era, immediate: true);
      _updateTick();
    } catch (_) {
      // Missing audio never blocks the puzzle or its saved state.
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (enabled && !_started) {
      unawaited(start(_era, clockRunning: _clockRunning));
      return;
    }
    setEra(_era, immediate: true);
    _updateTick();
  }

  void setClockRunning(bool value) {
    _clockRunning = value;
    _updateTick();
  }

  void setEra(Era era, {bool immediate = false}) {
    _era = era;
    _fadeTimer?.cancel();
    if (!_started) return;
    final targetPast = _enabled && era == Era.past ? 0.38 : 0.0;
    final targetFuture = _enabled && era == Era.future ? 0.39 : 0.0;
    if (immediate) {
      _pastVolume = targetPast;
      _futureVolume = targetFuture;
      _applyVolumes();
      _updateTick();
      return;
    }
    final fromPast = _pastVolume;
    final fromFuture = _futureVolume;
    var step = 0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      step++;
      final ratio = step / 20;
      _pastVolume = fromPast + (targetPast - fromPast) * ratio;
      _futureVolume = fromFuture + (targetFuture - fromFuture) * ratio;
      _applyVolumes();
      if (step >= 20) timer.cancel();
    });
    _updateTick();
  }

  void _applyVolumes() {
    unawaited(_past.setVolume(_pastVolume).catchError((_) {}));
    unawaited(_future.setVolume(_futureVolume).catchError((_) {}));
  }

  void play(String name, {double volume = 0.75}) {
    if (!_enabled) return;
    unawaited(
      _effects
          .play(AssetSource('audio/$name.wav'), volume: volume)
          .catchError((_) {}),
    );
  }

  /// Mio's recorded line [id]; any line still playing is cut off first.
  /// A short breath after the line appears before Mio starts speaking.
  void speak(String id) {
    _voiceDelay?.cancel();
    unawaited(_voice.stop().catchError((_) {}));
    if (!_enabled) return;
    _voiceDelay = Timer(const Duration(milliseconds: 280), () {
      unawaited(
        _voice.play(AssetSource('voice/$id.m4a'), volume: 1).catchError((_) {}),
      );
    });
  }

  void stopVoice() {
    _voiceDelay?.cancel();
    unawaited(_voice.stop().catchError((_) {}));
  }

  void _updateTick() {
    _tickTimer?.cancel();
    _whisperTimer?.cancel();
    if (!_enabled || !_clockRunning || _era != Era.future) return;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(
        _tick
            .play(AssetSource('audio/se_tick.wav'), volume: 0.16)
            .catchError((_) {}),
      );
    });
    _whisperTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_random.nextDouble() < 0.35) play('se_whisper', volume: 0.12);
    });
  }

  Future<void> dispose() async {
    _fadeTimer?.cancel();
    _tickTimer?.cancel();
    _whisperTimer?.cancel();
    _voiceDelay?.cancel();
    await Future.wait([
      _past.dispose(),
      _future.dispose(),
      _effects.dispose(),
      _tick.dispose(),
      _voice.dispose(),
    ]);
  }
}
