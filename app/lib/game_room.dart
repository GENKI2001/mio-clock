import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'ads.dart';
import 'data/hotspots.dart';
import 'data/mio_voice.dart';
import 'data/story_text.dart';
import 'game_progress.dart';
import 'soundscape.dart';
import 'widgets/dialogue_panel.dart';
import 'widgets/letter_panel.dart';
import 'widgets/meta_panels.dart';
import 'widgets/puzzle_panels.dart';
import 'widgets/scenes.dart';

const _gold = Color(0xFFE8BF79);
const _paper = Color(0xFFF3E6C8);
const _zoomDuration = Duration(milliseconds: 480);

enum _Panel { document, notebook, hint, menu, choice }

/// Full-screen close-ups the room cuts to.
enum _Scene {
  workbench,
  lock,
  boxLock,
  baseLock,
  baseOpen,
  calendar,
  newspaper,
  pillar,
  door,
}

class GameRoom extends StatefulWidget {
  const GameRoom({
    super.key,
    required this.progress,
    required this.endings,
    required this.soundOn,
    required this.onSoundChanged,
    required this.onSave,
    required this.onTitle,
    required this.onRestart,
    required this.onEnding,
    this.rewardGate,
  });

  final GameProgress progress;
  final Set<String> endings;
  final bool soundOn;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<GameProgress> onSave;
  final VoidCallback onTitle;
  final VoidCallback onRestart;
  final ValueChanged<String> onEnding;

  /// Plays a rewarded ad and reports whether it was watched through. Tests
  /// pass their own; the app uses AdMob.
  final Future<bool> Function()? rewardGate;

  @override
  State<GameRoom> createState() => _GameRoomState();
}

class _GameRoomState extends State<GameRoom> {
  final Soundscape _audio = Soundscape();
  _Panel? _panel;
  _Scene? _scene;
  bool _doorWatchIn = false;

  /// While set, the workbench tin shows one still frame per dialogue line
  /// (and whether the gear still lies on the bench).
  List<(TinLook, bool)>? _tinFrames;
  String? _documentId;
  String? _selectedItem;
  List<DialogueLine> _dialogue = [];
  int _dialogueIndex = 0;
  VoidCallback? _afterDialogue;
  List<String> _choices = [];
  ValueChanged<int>? _onChoice;
  bool _choiceRequired = false;
  String _choiceTitle = '';
  String _choiceDescription = '';
  final List<int> _drawerDigits = [0, 0, 0];
  final List<int> _boxDigits = [0, 0, 0, 0];
  final List<int> _baseDigits = [0, 0, 0];
  bool _hintLoading = false;
  String? _hintMessage;
  bool _confirmReset = false;
  bool _largeText = false;
  bool _soundOn = true;
  bool _unreadNote = false;
  bool _timeFlash = false;
  Timer? _flashTimer;
  CloseUpZone? _focus;
  CloseUpZone? _lastFocus;
  Timer? _focusTimer;

  GameProgress get _progress => widget.progress;
  bool get _past => _progress.era == Era.past;
  String get _mioExpression =>
      _dialogue.isNotEmpty && _dialogue[_dialogueIndex].speaker == 'ミオ'
      ? (_dialogue[_dialogueIndex].expression ?? 'normal')
      : 'normal';
  String get _mioAsset => switch (_mioExpression) {
    'smile' => 'assets/images/mio_14_smile.png',
    'surprise' => 'assets/images/mio_14_surprise.png',
    'embarrassed' => 'assets/images/mio_14_embarrassed.png',
    'proud' => 'assets/images/mio_14_proud.png',
    'sad' => 'assets/images/mio_14_sad.png',
    _ => 'assets/images/mio_14.png',
  };

  @override
  void initState() {
    super.initState();
    _soundOn = widget.soundOn;
    _audio.setEnabled(_soundOn);
    unawaited(
      _audio.start(_progress.era, clockRunning: _progress.clockRunning),
    );
    if (_gate == 'talk') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resumeTour();
      });
    }
    if (!_progress.introSeen) {
      _progress.introSeen = true;
      _progress.notes.add('n_watchMT');
      widget.onSave(_progress);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showDialogue(introLines);
      });
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _focusTimer?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _persist() => widget.onSave(_progress);

  void _note(String id) {
    if (_progress.notes.add(id)) _unreadNote = true;
    _persist();
  }

  void _showDialogue(List<DialogueLine> lines, [VoidCallback? after]) {
    if (lines.isEmpty) {
      after?.call();
      return;
    }
    setState(() {
      _panel = null;
      _dialogue = lines;
      _dialogueIndex = 0;
      _voiceLine();
      _afterDialogue = after;
    });
  }

  /// Mio speaks her lines aloud; anyone else's line silences her.
  void _voiceLine() {
    final line = _dialogue[_dialogueIndex];
    final id = line.speaker == 'ミオ' ? mioVoice[line.text] : null;
    if (id != null) {
      _audio.speak(id);
    } else {
      _audio.stopVoice();
    }
  }

  void _say(String text, [VoidCallback? after]) =>
      _showDialogue([DialogueLine(text)], after);

  void _advanceDialogue() {
    if (_dialogueIndex + 1 < _dialogue.length) {
      setState(() {
        _dialogueIndex++;
        _voiceLine();
      });
      return;
    }
    final after = _afterDialogue;
    _audio.stopVoice();
    setState(() {
      _tinFrames = null;
      _dialogue = [];
      _dialogueIndex = 0;
      _afterDialogue = null;
    });
    after?.call();
  }

  void _showChoice(
    String title,
    String description,
    List<String> options,
    ValueChanged<int> onChoose, {
    bool requiredChoice = false,
  }) {
    setState(() {
      _panel = _Panel.choice;
      _choices = options;
      _onChoice = onChoose;
      _choiceRequired = requiredChoice;
      _choiceTitle = title;
      _choiceDescription = description;
    });
  }

  void _showDocument(String id, {bool add = true}) {
    setState(() {
      if (add && _progress.docs.add(id)) _unreadNote = true;
      _documentId = id;
      _panel = _Panel.document;
    });
    _persist();
  }

  void _closePanel() {
    setState(() {
      _panel = null;
      _confirmReset = false;
    });
  }

  void _flash() {
    _flashTimer?.cancel();
    setState(() => _timeFlash = true);
    _flashTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _timeFlash = false);
    });
  }

  /// The workbench and the pillar exist in both eras, so jumping while
  /// looking at them shows the same spot a hundred years apart.
  void _keepSceneAcrossTime() {
    if (_scene != _Scene.workbench && _scene != _Scene.pillar) _scene = null;
  }

  void _travel() {
    if (_panel != null || _dialogue.isNotEmpty) return;
    if (_gate == 'clock' || _gate == 'talk') return;
    if (_scene == _Scene.door && _watchFitsDoor) {
      _insertWatch();
      return;
    }
    if (_past) {
      final count = _progress.farewellCount;
      final farewell = count == 0
          ? farewellLines.first
          : farewellLines[1 + (count - 1) % 4];
      _showDialogue([farewell], () {
        setState(() {
          _progress.travel();
          _selectedItem = null;
          _keepSceneAcrossTime();
        });
        _persist();
        _audio.play('se_timeshift');
        _audio.setEra(_progress.era);
        _flash();
      });
    } else {
      final firstVisit = !_progress.metMio;
      setState(() {
        _progress.travel();
        _selectedItem = null;
        _keepSceneAcrossTime();
      });
      _persist();
      _audio.play('se_timeshift');
      _audio.setEra(_progress.era);
      _flash();
      if (!firstVisit && _gate == 'talk') {
        // Arrive looking at Mio, who has been waiting for the report.
        setState(() => _focus = _lastFocus = closeUpZones['door']);
        _focusTimer = Timer(_zoomDuration, () {
          if (mounted) _resumeTour();
        });
      } else if (firstVisit) {
        _showDialogue(meetOpening, () {
          _showChoice('ミオに答える', 'どこから入ってきた?', ['時計をいじっていたら、変な部屋に……'], (_) {
            _showDialogue(meetWatch, () {
              _showChoice('ミオに答える', 'あなたの時代は?', ['2026年'], (_) {
                _showDialogue(meetWelcome, () {
                  _showChoice(
                    'ミオに答える',
                    '100年後のこの家は……',
                    ['廃墟になっていた', '誰もいなくて、真っ暗だった'],
                    (index) {
                      _showDialogue([
                        meetFutureAnswers[index],
                        ...meetStuck,
                      ], _pointAtClock);
                    },
                    requiredChoice: true,
                  );
                });
              }, requiredChoice: true);
            });
          }, requiredChoice: true);
        });
      }
    }
  }

  /// Mio points at the big clock: the camera looks, then comes back, and she
  /// sends the player to check it in 2026.
  void _pointAtClock() {
    setState(() => _focus = _lastFocus = closeUpZones['clock']);
    _focusTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _focus = null);
      _focusTimer = Timer(_zoomDuration, () {
        if (!mounted) return;
        _showDialogue(meetClockExplain, () {
          _progress.flags['tourStarted'] = true;
          _persist();
          setState(() {});
        });
      });
    });
  }

  /// Back from seeing the broken clock, the conversation with Mio goes on.
  void _resumeTour() {
    _showDialogue(meetReport, () {
      _showChoice('ミオに答える', '', ['でも、過去だと体が透けちゃって物を受け取れない'], (_) {
        _showDialogue(meetPlan, () {
          _showChoice('ミオに答える', '足りないパーツは……', ['歯車・振り子・ねじ', 'また戻って確認する'], (
            index,
          ) {
            if (index == 1) {
              _progress.flags['clockChecked'] = false;
              _persist();
              _showDialogue(const [
                DialogueLine(
                  'うん、もう一回見てきて!',
                  speaker: 'ミオ',
                  expression: 'smile',
                ),
              ]);
              return;
            }
            _showDialogue(meetTeam, () {
              _progress.flags['tourDone'] = true;
              _persist();
              setState(() {});
            });
          }, requiredChoice: true);
        });
      }, requiredChoice: true);
    });
  }

  /// Walks the camera up to [target] before examining it, like stepping
  /// toward a shelf in a point-and-click escape room. Once close, further
  /// taps in the same view act right away.
  /// While the opening walks the player through it, only one thing answers:
  /// 'watch' (the button in the corner), 'clock', or 'talk' (Mio is about to
  /// speak). Null once the room is free to explore.
  String? get _gate {
    final p = _progress;
    if (!p.metMio) return 'watch';
    if (!p.flag('tourStarted') || p.flag('tourDone')) return null;
    if (!p.flag('clockChecked')) return _past ? 'watch' : 'clock';
    return _past ? 'talk' : 'watch';
  }

  void _approach(String spotId, VoidCallback action) {
    final gate = _gate;
    if (gate != null && gate != spotId) return;
    if (_panel != null || _dialogue.isNotEmpty) return;
    if (_focusTimer?.isActive ?? false) return;
    if (_focus != null) {
      action();
      return;
    }
    setState(() => _focus = _lastFocus = zoneFor(spotId, past: _past));
    _focusTimer = Timer(_zoomDuration, () {
      if (mounted) action();
    });
  }

  void _stepBack() {
    if (_focusTimer?.isActive ?? false) return;
    setState(() {
      _scene = null;
      _focus = null;
    });
  }

  void _interact(String id) {
    if (_panel != null || _dialogue.isNotEmpty) return;
    if (!_past && _selectedItem != null) {
      _useSelectedItem(id);
      return;
    }
    switch (id) {
      case 'clock':
        _clock();
      case 'clockBase':
        _clockBase();
      case 'pillar':
        _pillar();
      case 'calendar':
        _calendar();
      case 'drawer':
        _drawer();
      case 'workbench':
        _openScene(_Scene.workbench);
      case 'blackboard':
        _blackboard();
      case 'shelfBox':
        _shelfBox();
      case 'chair':
        _chair();
      case 'newspaper':
        _progress.docs.add('newspaper');
        _persist();
        _openScene(_Scene.newspaper);
      case 'door':
        _door();
      case 'mio':
        _mio();
      case 'window':
        if (!_past && _progress.flag('codeOnWindow')) {
          _note('n_windowCode');
          _say('割れずに残った左下のガラスに、細い傷で数字が刻まれている。「2 7 5」。……ミオの字だ。');
        } else {
          _say(
            _past
                ? '窓の外に下町の瓦屋根。どこかで豆腐屋のラッパが鳴っている。'
                : '割れた窓の向こうに、光る高層の街並み。百年後の夜景だ。',
          );
        }
      case 'fireplace':
        _fireplace();
      case 'desk':
        _say(
          _past ? '父親の机。設計図が広げてある。「百年時計 図面 其ノ三」' : '埃に覆われた机。引き出しには真鍮の錠がついている。',
        );
      default:
        _say('何も見つからない。');
    }
  }

  void _openScene(_Scene scene) {
    setState(() => _scene = scene);
  }

  void _calendar() {
    if (!_past) {
      _say('壁に錆びた釘が一本。何かが掛けてあった跡だけが、日焼けせずに四角く残っている。');
      return;
    }
    _note('n_calendar');
    _openScene(_Scene.calendar);
  }

  void _drawer() {
    if (_past) {
      _showDialogue(const [
        DialogueLine('引き出しは半開きだ。中に真鍮のねじ巻き鍵が入っている。'),
        DialogueLine(
          'それはお父様の大事なねじ巻き鍵。さわっちゃだめ! ……って言っても、幽霊さんは持てないか',
          speaker: 'ミオ',
        ),
      ]);
    } else if (_progress.drawerOpened) {
      _say('空っぽの引き出し。');
    } else {
      _progress.flags['drawerSeen'] = true;
      _persist();
      _openScene(_Scene.lock);
    }
  }

  void _unlockDrawer() {
    if (_progress.tryOpenDrawer(_drawerDigits)) {
      _audio.play('se_unlock');
      _persist();
      _showDialogue(
        const [
          DialogueLine('かちり。……錠が外れた。'),
          DialogueLine('引き出しの中には、真鍮のねじ巻き鍵と、古いマッチ箱と、黄ばんだ封筒が入っている。'),
        ],
        () {
          setState(() => _scene = null);
          _showDocument('memo1', add: false);
        },
      );
    }
  }

  // --- The workbench, seen from above --------------------------------------

  void _sceneGear() {
    final first = !_progress.flag('gearSeen');
    _progress.flags['gearSeen'] = true;
    _persist();
    _showDialogue([
      const DialogueLine('手をのばしたが、指は歯車をすり抜けた。……この時代では、物に触れられない'),
      if (first) ...const [
        DialogueLine('あっ、それ! 大時計のやつ!', speaker: 'ミオ', expression: 'surprise'),
        DialogueLine('お父様と私で削った、大時計の予備の歯車なの', speaker: 'ミオ'),
        DialogueLine(
          '百年後の大時計が壊れてるなら……この歯車、使えるかも!',
          speaker: 'ミオ',
          expression: 'proud',
        ),
        DialogueLine(
          'けど、あなた透けてるもの。持ち物は、きっと2026年に持っていけない',
          speaker: 'ミオ',
          expression: 'sad',
        ),
        DialogueLine(
          'かといって、ここに置いたままだと百年で錆びちゃうし……。うーん',
          speaker: 'ミオ',
          expression: 'sad',
        ),
      ],
    ]);
  }

  void _sceneTin() {
    if (_past) {
      if (_progress.gearInTin) {
        _showDialogue(const [
          DialogueLine(
            '歯車は、ちゃんとしまったよ。百年後に開けてね。……ちくたく、ちくたく',
            speaker: 'ミオ',
            expression: 'smile',
          ),
        ]);
      } else if (!_progress.flag('gearSeen')) {
        _showDialogue(const [
          DialogueLine(
            '私の宝物缶。ふたを蝋で封じてあるから、水も虫も入らないの。百年だって平気よ',
            speaker: 'ミオ',
            expression: 'proud',
          ),
        ]);
      } else if (_progress.sealGearInTin()) {
        _audio.play('se_gear', volume: 0.4);
        _persist();
        // Still frames of the tin, one per line, so the player sees it
        // opened, filled and sealed.
        _tinFrames = const [
          (TinLook.closed1926, true),
          (TinLook.open1926, true),
          (TinLook.open1926, true),
          (TinLook.gear1926, false),
          (TinLook.gear1926, false),
          (TinLook.closed1926, false),
          (TinLook.closed1926, false),
        ];
        _showDialogue(const [
          DialogueLine('そうだ、私の宝物缶!', speaker: 'ミオ', expression: 'surprise'),
          DialogueLine('ミオが缶のふたを外した。中は空っぽだ'),
          DialogueLine(
            'この缶はね、ふたを蝋で封じると、水も虫も入らないの。百年後まで錆びないまま、とっておける!',
            speaker: 'ミオ',
            expression: 'proud',
          ),
          DialogueLine('ミオは歯車を油紙でくるみ、そっと缶に収めた'),
          DialogueLine(
            'それから、手紙も入れておくね。百年後のあなたへ',
            speaker: 'ミオ',
            expression: 'smile',
          ),
          DialogueLine('ミオはふたを閉め、縁を蝋でぐるりと封じた'),
          DialogueLine(
            '缶はずっと、この作業台の上に置いておく。……ちくたく、ちくたく。はい、おまじない',
            speaker: 'ミオ',
            expression: 'smile',
          ),
        ]);
      }
      return;
    }
    if (_progress.tinOpened) {
      _say('空になった缶。内側だけは、百年前のままの色をしている。');
    } else if (_selectedItem == 'matches') {
      setState(() => _selectedItem = null);
      if (_progress.openTin()) {
        _audio.play('se_unlock');
        _persist();
        _tinFrames = const [
          (TinLook.sealed2026, false),
          (TinLook.gear2026, false),
          (TinLook.gear2026, false),
        ];
        _showDialogue(const [
          DialogueLine('マッチを擦って、ふたの縁の蝋をあぶる。固まっていた蝋が、とろりとやわらかくなった'),
          DialogueLine('ふたを開けると――油紙にくるまれた真鍮の歯車が、百年前と同じ輝きで入っていた。'),
          DialogueLine('歯車の下に、手紙が一通。'),
        ], () => _showDocument('memo2', add: false));
      }
    } else {
      _note('n_waxSeal');
      _say(
        'ミオが置いたのと同じ場所に、錆びた缶。ふたの縁が、石のように固まった蝋で封じられている。爪では歯が立たない。……温めれば、やわらかくなりそうだ。',
      );
    }
  }

  // --- The big clock ----------------------------------------------------------

  void _clock() {
    if (_past) {
      _showDialogue(const [
        DialogueLine('組み立て途中の大きな時計。中の歯車が陽を受けて光っている。'),
        DialogueLine(
          '百年時計! ねじを一度巻けば、百年動く……予定!',
          speaker: 'ミオ',
          expression: 'proud',
        ),
      ]);
      return;
    }
    if (!_progress.clockRunning) _note('n_clockStopped');
    if (_gate == 'clock') {
      _note('n_missingGear');
      _showDialogue(clockCheckLines, () {
        _progress.flags['clockChecked'] = true;
        _persist();
        setState(() {});
      });
      return;
    }
    if (!_progress.clockGearInstalled) {
      _note('n_missingGear');
      _say(
        '止まった大時計。文字盤の下の小窓が開いていて、中の歯車が一枚だけ抜けている。ぽっかり空いた軸に、ちょうど手のひらくらいの歯車が収まりそうだ。',
      );
    } else if (!_progress.clockPendulumInstalled) {
      _say('歯車は収まった。けれど、ガラスの奥の振り子を吊るす金具が空っぽだ。');
    } else if (!_progress.clockOiled) {
      _say(
        _progress.flag('springRusty')
            ? 'ぜんまいが赤く錆びついている。時計油をささないと、鍵を回せそうにない。'
            : '部品は揃った。あとはねじを巻くだけだ。',
      );
    } else if (!_progress.clockRunning) {
      _say('油の差されたぜんまいが、鈍く光っている。あとはねじを巻くだけだ。');
    } else {
      _say('大時計が、ちくたくと時を刻んでいる。');
    }
  }

  void _shelfBox() {
    if (_past) {
      _showDialogue(const [
        DialogueLine(
          '私の小物入れ。……中身? ひみつ!',
          speaker: 'ミオ',
          expression: 'embarrassed',
        ),
      ]);
    } else if (_progress.boxOpened) {
      _say('空になった小箱。');
    } else {
      _note('n_boxLock');
      _progress.flags['boxLockSeen'] = true;
      _persist();
      _say(
        '棚のいちばん下に、真鍮の錠のついた小箱。ふたに彫られた文字。「ミオの背が、前の年から いちばん伸びた年を 西暦で」',
        () => _openScene(_Scene.boxLock),
      );
    }
  }

  void _unlockBox() {
    if (_progress.tryOpenBox(_boxDigits)) {
      _audio.play('se_unlock');
      _persist();
      _note('n_blankLetter');
      _showDialogue(const [
        DialogueLine('かちり、と小箱のふたが開いた。'),
        DialogueLine('中には、小さなドライバーと、折りたたんだ便箋。'),
        DialogueLine('便箋を開いてみたが、真っ白だ。……鼻を近づけると、かすかにみかんの匂いがする。'),
      ], () => setState(() => _scene = null));
    }
  }

  void _clockBase() {
    if (_past) {
      _showDialogue(const [
        DialogueLine('大時計の台座に、小さな引き出しがついている。'),
        DialogueLine('そこはお父様の油差しの置き場所。……今は空っぽ', speaker: 'ミオ'),
      ]);
    } else if (!_progress.oilHidden) {
      _say('台座に小さな引き出し。真鍮の錠がついているが、留め金は外れている。中は乾いた埃だけだ。');
    } else if (!_progress.flag('baseUnlocked')) {
      _say(
        '台座の小さな引き出しに、真鍮の錠がかかっている。……ミオが、お父様の錠をかけてくれたものだ。',
        () => _openScene(_Scene.baseLock),
      );
    } else {
      _openScene(_Scene.baseOpen);
    }
  }

  void _unlockBase() {
    if (!_progress.tryOpenBase(_baseDigits)) return;
    _audio.play('se_unlock');
    _persist();
    _showDialogue(const [
      DialogueLine('かちり。……台座の引き出しが、するりと開いた。'),
    ], () => setState(() => _scene = _Scene.baseOpen));
  }

  void _sceneOil() {
    if (!_progress.takeOil()) return;
    _persist();
    _showDialogue(const [
      DialogueLine('蝋で口を封じた小瓶。ラベルに、ミオの字。「とけいあぶら ひゃくねんぶん」'),
      DialogueLine('時計油を手に入れた。'),
    ]);
  }

  // --- The height pillar ------------------------------------------------------

  List<HeightMark> get _heightMarks => [
    const HeightMark(1926, 142),
    if (!_past) ...const [
      HeightMark(1927, 145),
      HeightMark(1928, 151),
      HeightMark(1929, 153),
      HeightMark(1930, 154),
    ],
  ];

  /// Until the box's riddle points at Mio's height, the pillar is just a
  /// pillar: looking shows it, and nothing happens.
  void _pillar() {
    if (_past && !_progress.heightMarked && _progress.flag('boxLockSeen')) {
      _measureMio();
      return;
    }
    if (!_past && _progress.heightMarked) _note('n_pillar');
    _openScene(_Scene.pillar);
  }

  /// The player asks; Mio wonders where. Finding the place (the pillar) is
  /// left to the player, with no highlight or camera move.
  void _askToMeasure() {
    _showDialogue(
      const [
        DialogueLine('ミオの背を、測ってみてほしいんだ', speaker: 'あなた'),
        DialogueLine('背を? いいよ! 測りたいの?', speaker: 'ミオ', expression: 'smile'),
        DialogueLine('……でも、どこで測ればいい?', speaker: 'ミオ'),
      ],
      () {
        // Where to measure is left for the player to work out.
        _progress.flags['measureAsked'] = true;
        _persist();
        setState(() {});
      },
    );
  }

  /// Mio measures herself; the player can only watch. The mark goes into
  /// the wood only after she has said what she is about to do.
  void _measureMio() {
    _showDialogue(
      const [
        DialogueLine(
          'あ、その柱! 背比べの柱にしようと思ってたの。今日で十四歳だし、記念に測ろうかな!',
          speaker: 'ミオ',
          expression: 'smile',
        ),
        DialogueLine('ミオは柱に背中をつけ、頭の上に定規を当てた'),
        DialogueLine('……かかとが浮いている'),
        DialogueLine('う、浮いてないもん!', speaker: 'ミオ', expression: 'embarrassed'),
      ],
      () {
        _audio.play('se_carve');
        _progress.markHeight();
        _persist();
        _openScene(_Scene.pillar);
        _showDialogue(const [
          DialogueLine('ミオは小刀で、柱に一本の印を刻んだ'),
          DialogueLine(
            '1926、142……っと。年も彫っておけば、百年たってもわかるでしょ? えへへ',
            speaker: 'ミオ',
            expression: 'smile',
          ),
          DialogueLine(
            'これから毎年、誕生日に測るんだ。百年後に見て、びっくりしてよ!',
            speaker: 'ミオ',
            expression: 'proud',
          ),
        ]);
      },
    );
  }

  // --- Other spots ------------------------------------------------------------

  void _blackboard() {
    if (!_past) {
      if (_progress.flag('codeOnBoard') && !_progress.flag('codeOnWindow')) {
        _progress.flags['boardFaded'] = true;
        _note('n_boardFaded');
        _say('黒板の端に、白い粉の跡。……数字が書いてあったようだが、百年分の煤に埋もれて読めない。');
      } else {
        _say('黒板は煤けて、ほとんど何も読めない。');
      }
      return;
    }
    _showDialogue(const [
      DialogueLine('黒板に、チョークで大時計の歯車の図がびっしり描いてある。'),
      DialogueLine(
        '百年時計の設計のお勉強! お父様より上手でしょ?',
        speaker: 'ミオ',
        expression: 'proud',
      ),
    ]);
  }

  void _chair() {
    if (_past) {
      _progress.flags['favoritePlace'] = true;
      _note('n_favoritePlace');
      _showDialogue(const [
        DialogueLine(
          'お父様の椅子。私、ここに座って、お父様の仕事を見てるのがいちばん好き',
          speaker: 'ミオ',
          expression: 'smile',
        ),
      ]);
    } else if (_progress.chairSearched) {
      _say('外した床板の下は空っぽだ。');
    } else if (!_progress.docs.contains('memo3')) {
      _say('脚の折れた椅子。');
    } else if (!_progress.flag('favoritePlace')) {
      _say('脚の折れた椅子。……振り子は、ミオの「いちばん好きな場所」の真下にあるという。ここなのだろうか。');
    } else if (_selectedItem == 'driver') {
      setState(() => _selectedItem = null);
      if (_progress.searchChair()) {
        _audio.play('se_unlock');
        _persist();
        _showDialogue(const [
          DialogueLine('ドライバーで、椅子の真下の床板のねじを外していく。'),
          DialogueLine('床板を持ち上げると、油布にくるまれた真鍮の振り子と、手紙が一通。'),
        ], () => _showDocument('memo4', add: false));
      }
    } else {
      _note('n_screwedBoard');
      _say('ミオのいちばん好きな場所――お父様の椅子。その真下の床板だけ、小さなねじで留めてある。');
    }
  }

  void _fireplace() {
    final item = _selectedItem;
    if (_past) {
      final tell = _progress.inventory.contains('blankLetter');
      if (tell) {
        _progress.flags['inkTalk'] = true;
        _persist();
      }
      _showDialogue([
        const DialogueLine('春なので火は入っていない。煤のにおい。'),
        if (tell) ...const [
          DialogueLine('百年後の小箱から出てきた、白紙の手紙のことを話した'),
          DialogueLine(
            'みかんの匂い? それ、きっと私のひみつの手紙! みかんの汁で書くと、乾いたら見えなくなるの',
            speaker: 'ミオ',
            expression: 'proud',
          ),
          DialogueLine(
            '寒い日はね、この暖炉の火にあぶって読むんだ。字が茶色く浮かんでくるんだよ',
            speaker: 'ミオ',
            expression: 'smile',
          ),
        ],
      ]);
      return;
    }
    setState(() => _selectedItem = null);
    if (!_progress.fireLit) {
      if (item == 'matches' && _progress.lightFire()) {
        _note('n_fire');
        _audio.play('se_timeshift', volume: 0.3);
        _persist();
        _showDialogue(const [
          DialogueLine('煤の奥に、燃え残りの薪と乾いた枯れ葉。マッチを擦って、そっと差し入れる。'),
          DialogueLine('ぱち、ぱち。……百年ぶりの火が、部屋を橙色に照らした。'),
        ]);
      } else {
        _say('崩れかけた暖炉。煤の奥に、燃え残りの薪と乾いた枯れ葉が積もっている。火をつければ、まだ燃えそうだ。');
      }
    } else if (item == 'blankLetter' && _progress.revealLetter()) {
      _persist();
      _showDialogue(const [
        DialogueLine('白紙の便箋を、炎にかざしてみる。'),
        DialogueLine('じわり、と茶色い文字が浮かび上がってきた。……ミオの字だ。'),
      ], () => _showDocument('memo3', add: false));
    } else {
      _say('暖炉の火が、ぱちぱちと燃えている。手をかざすと、あたたかい。');
    }
  }

  void _useSelectedItem(String id) {
    final item = _selectedItem;
    if (id == 'fireplace') {
      _fireplace();
      return;
    }
    if (id == 'chair' && item == 'driver') {
      _chair();
      return;
    }
    if (id == 'workbench' && item == 'matches') {
      _openScene(_Scene.workbench);
      return;
    }
    setState(() => _selectedItem = null);
    if (id != 'clock') {
      _say('ここでは使えないようだ。');
      return;
    }
    switch (item) {
      case 'gear':
        if (_progress.installGear()) {
          _audio.play('se_gear');
          _persist();
          _say('歯車を軸にはめると、かちり、と小気味よい音がした。');
        }
      case 'pendulum':
        if (!_progress.boxOpened) {
          _say('振り子を吊るす場所が見当たらない。');
        } else if (_progress.installPendulum()) {
          _audio.play('se_gear');
          _persist();
          _say('振り子を金具に吊るした。');
        }
      case 'oil':
        if (!_progress.clockPendulumInstalled) {
          _say('まだ部品が揃っていない。');
        } else if (_progress.oilClock()) {
          _audio.play('se_gear', volume: 0.5);
          _persist();
          _say('ミオの時計油を、ぜんまいに一滴ずつ差していく。赤い錆がほどけ、真鍮の色がのぞいた。');
        }
      case 'windKey':
        if (_progress.windClock()) {
          _audio.play('se_wind');
          _audio.setClockRunning(true);
          _persist();
          _flash();
          _showDialogue(const [
            DialogueLine('ちく、たく。'),
            DialogueLine('ちく、たく、ちく、たく――百年ぶりに、大時計が時を刻みはじめた'),
            DialogueLine('扉のほうで、かちりと何かが噛み合う音がした'),
            DialogueLine('……ガラスの奥で、一瞬、誰かと目が合った気がした'),
          ]);
        } else if (_progress.clockGearInstalled &&
            _progress.clockPendulumInstalled &&
            !_progress.clockOiled) {
          _progress.flags['springRusty'] = true;
          _note('n_rustySpring');
          _say('鍵を差して回そうとしたが、びくともしない。のぞきこむと、ぜんまいが真っ赤に錆びついていた。……時計油がほしい。');
        } else {
          _say('鍵を差してねじを巻いてみたが、ぜんまいが空回りするだけだ。まだ何かが足りない。');
        }
      default:
        _say('ここでは使えないようだ。');
    }
  }

  /// The door's recess only answers once the clock runs and Mio has
  /// promised to hand her watch down to the player's time.
  bool get _watchFitsDoor =>
      !_past && _progress.clockRunning && _progress.flag('watchPromised');

  void _door() {
    if (_past) {
      _showDialogue(const [
        DialogueLine(
          'そこ、お父様が鍵を持って出かけちゃったの。……だから今日は、あなたとふたりきり!',
          speaker: 'ミオ',
          expression: 'sad',
        ),
      ]);
      return;
    }
    _note('n_door');
    _openScene(_Scene.door);
    if (!_progress.clockRunning) {
      _say('鍵穴のない扉。中央に、懐中時計の形をしたくぼみが彫られている。……大時計が止まっているせいか、くぼみは冷たく沈黙している。');
    } else if (!_progress.flag('watchPromised')) {
      _progress.flags['doorRecessSeen'] = true;
      _persist();
      _say('くぼみの縁が、ほのかに光っている。丸い胴、上に竜頭と吊り輪。……この形、ミオが胸元に下げていた懐中時計にそっくりだ。');
    } else {
      _say('懐中時計の形のくぼみが、何かを待つように光っている。');
    }
  }

  void _mio() {
    // Requests that move the story forward come first, as they appear.
    final topics = <String>[
      if (_progress.flag('boxLockSeen') &&
          !_progress.heightMarked &&
          !_progress.flag('measureAsked'))
        '背を測ってほしい',
      if (_progress.flag('gearSeen') && !_progress.gearInTin) '歯車のこと',
      if (_progress.docs.contains('memo3') && !_progress.flag('favoritePlace'))
        '好きな場所',
      if (_progress.flag('springRusty') && !_progress.oilHidden) '錆びたぜんまい',
      if (_progress.flag('boardFaded') && !_progress.flag('codeOnWindow'))
        '黒板の数字',
      if (_progress.flag('doorRecessSeen') && !_progress.flag('watchPromised'))
        '扉のくぼみ',
      '百年時計のこと',
      'その懐中時計',
      if (_progress.heightMarked) '柱の印',
      'ヒントがほしい',
      'なんでもない',
    ];
    _showChoice('ミオと話す', '何について話す?', topics, (index) {
      final topic = topics[index];
      switch (topic) {
        case '百年時計のこと':
          _showDialogue(const [
            DialogueLine(
              'ねじを一度巻けば百年動く時計。百年後の誰かに、この音を届けたいの',
              speaker: 'ミオ',
              expression: 'proud',
            ),
            DialogueLine(
              '……あ、もう届いてる。あなたに!',
              speaker: 'ミオ',
              expression: 'smile',
            ),
          ]);
        case 'その懐中時計':
          _note('n_mioWatch');
          _showDialogue(const [
            DialogueLine('ミオの胸元の懐中時計は、あなたのものと傷の位置まで同じだった'),
            DialogueLine('お母様の形見。時をまたぐ時計なんだって', speaker: 'ミオ'),
          ]);
        case '背を測ってほしい':
          _askToMeasure();
        case '好きな場所':
          _progress.flags['favoritePlace'] = true;
          _note('n_favoritePlace');
          _showDialogue(const [
            DialogueLine(
              'いちばん好きな場所? お父様の椅子!',
              speaker: 'ミオ',
              expression: 'smile',
            ),
            DialogueLine(
              'あそこに座って、お父様が時計を組み立てるのを見てるの。ずっと見てても飽きないんだ',
              speaker: 'ミオ',
            ),
          ]);
        case '錆びたぜんまい':
          _progress.hideOil();
          _persist();
          _showDialogue(const [
            DialogueLine('百年後の大時計のぜんまいが、錆びついて回らないことを話した'),
            DialogueLine(
              '時計油が要るのね。……でも、ふつうの油は百年ももたない',
              speaker: 'ミオ',
              expression: 'sad',
            ),
            DialogueLine(
              'そうだ! 小瓶に詰めて、口を蝋で封じれば、空気が入らないから大丈夫',
              speaker: 'ミオ',
              expression: 'proud',
            ),
            DialogueLine('ミオは油差しから小瓶に時計油を移し、コルクを蝋で固めた'),
            DialogueLine(
              '大時計の台座の、小さな引き出しに入れておくね。お父様の油差しの置き場所なの',
              speaker: 'ミオ',
              expression: 'smile',
            ),
            DialogueLine('百年もあったら泥棒が入るかもしれないから、お父様の錠をかけておく', speaker: 'ミオ'),
            DialogueLine(
              '番号は、私も知らないの。お父様が帰ってきたら聞いて、黒板に書いておくね!',
              speaker: 'ミオ',
              expression: 'proud',
            ),
          ]);
          _progress.flags['codeOnBoard'] = true;
          _persist();
        case '歯車のこと':
          _showDialogue(const [
            DialogueLine('百年もつ場所……窓辺は雨が当たるし、暖炉は煤だらけになるし……', speaker: 'ミオ'),
            DialogueLine(
              '私の宝物缶なら、ぜったい大丈夫なのに!',
              speaker: 'ミオ',
              expression: 'proud',
            ),
          ]);
        case '柱の印':
          _showDialogue(const [
            DialogueLine(
              '毎年の誕生日に測るからね。百年後に見て、びっくりしてよ!',
              speaker: 'ミオ',
              expression: 'smile',
            ),
          ]);
        case '黒板の数字':
          _progress.flags['codeOnWindow'] = true;
          _note('n_codeOnWindow');
          _showDialogue(const [
            DialogueLine('百年後の黒板は煤けて、数字が読めなかったことを話した'),
            DialogueLine(
              'えっ、消えちゃってた? ……チョークじゃ、百年もたないかぁ',
              speaker: 'ミオ',
              expression: 'sad',
            ),
            DialogueLine('うーん……消えないもの、消えないもの……', speaker: 'ミオ'),
            DialogueLine(
              'そうだ! お父様のガラス切り! 窓ガラスに刻めば、百年たっても消えない!',
              speaker: 'ミオ',
              expression: 'proud',
            ),
            DialogueLine('窓ガラスって……割れたら消えちゃいそうだけど……', speaker: 'あなた'),
            DialogueLine('消えないの! 大丈夫!', speaker: 'ミオ', expression: 'proud'),
            DialogueLine(
              '番号を聞いたら、窓の左下のガラスに刻んでおくね。割れないように祈ってて!',
              speaker: 'ミオ',
              expression: 'smile',
            ),
          ]);
        case '扉のくぼみ':
          _promiseWatch();
        case 'ヒントがほしい':
          _showHint();
        default:
          _closePanel();
      }
    });
  }

  /// Mio learns her own watch is the door's key, and promises to hand it
  /// down through the century to the player.
  void _promiseWatch() {
    _progress.flags['watchPromised'] = true;
    _note('n_watchPromise');
    _showDialogue(const [
      DialogueLine('百年後の扉に、懐中時計の形をしたくぼみがあることを話した'),
      DialogueLine('懐中時計の形のくぼみ……? うーん、そんなの、私も見たことない', speaker: 'ミオ'),
      DialogueLine(
        'お父様のからくりって、私にもわからないことだらけなの',
        speaker: 'ミオ',
        expression: 'sad',
      ),
      DialogueLine('ふと、ミオの胸元の懐中時計に目が留まる。丸い胴、竜頭と吊り輪――あのくぼみと、同じ形だ'),
      DialogueLine('ミオが持っているその時計、ぴったり合いそうな気がする', speaker: 'あなた'),
      DialogueLine('えっ、私の?', speaker: 'ミオ', expression: 'surprise'),
      DialogueLine('ミオは胸元の懐中時計を外して、じっと見つめた'),
      DialogueLine(
        'なるほど……! この時計を、100年後まで届ければいいのね!',
        speaker: 'ミオ',
        expression: 'surprise',
      ),
      DialogueLine(
        'じゃあこの懐中時計、あなたの時代まで届くように、大切に受け継いでいく',
        speaker: 'ミオ',
        expression: 'proud',
      ),
      DialogueLine('必ず受け取ってね', speaker: 'ミオ', expression: 'smile'),
    ]);
  }

  void _showHint() {
    setState(() {
      _hintMessage = null;
      _panel = _Panel.hint;
    });
  }

  /// A rewarded ad unlocks the next hint. The game falls silent while it
  /// plays and picks the sound back up afterwards.
  Future<void> _watchForHint() async {
    if (_hintLoading) return;
    setState(() {
      _hintLoading = true;
      _hintMessage = null;
    });
    _audio.setEnabled(false);
    final earned = await (widget.rewardGate ?? HintAds.instance.watchForHint)();
    if (!mounted) return;
    _audio.setEnabled(_soundOn);
    setState(() {
      _hintLoading = false;
      if (earned) {
        _progress.revealHint(_progress.currentStage(widget.endings));
      } else {
        _hintMessage = '広告を最後まで見られなかったため、ヒントは開きませんでした。通信環境を確かめて、もう一度お試しください。';
      }
    });
    _persist();
  }

  /// The watch in the player's hand goes into the door: it was Mio's all
  /// along, handed down across a hundred years.
  void _insertWatch() {
    _audio.play('se_door');
    setState(() => _doorWatchIn = true);
    _progress.flags['watchInserted'] = true;
    _persist();
    _showDialogue(const [
      DialogueLine('懐中時計を、扉のくぼみに当てる'),
      DialogueLine('かちり。……吸い込まれるように、ぴったりと収まった'),
      DialogueLine('裏蓋の「M.T.」。……時任ミオ'),
      DialogueLine('祖母から受け継いだこの時計は、ミオが約束どおり、百年かけて受け継ぎ、届けてくれたものだった'),
      DialogueLine('扉の奥で歯車がかみ合い、ゆっくりと錠がほどけていく'),
    ], () => widget.onEnding('normal'));
  }

  /// Turns one wheel; the lock springs open by itself the moment the right
  /// number lines up.
  void _turnWheel(
    List<int> digits,
    int index,
    int delta,
    VoidCallback tryOpen,
  ) {
    setState(() => digits[index] = (digits[index] + delta + 10) % 10);
    tryOpen();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: TweenAnimationBuilder<Rect?>(
            tween: RectTween(
              begin: stageRect,
              end: _focus?.camera ?? stageRect,
            ),
            duration: _zoomDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, camera, child) {
              final view = camera ?? stageRect;
              final scale = stageRect.width / view.width;
              return Transform(
                transform: Matrix4.diagonal3Values(scale, scale, 1)
                  ..setTranslationRaw(-view.left * scale, -view.top * scale, 0),
                child: child,
              );
            },
            child: Stack(fit: StackFit.expand, children: _world()),
          ),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99071322),
                  Colors.transparent,
                  Color(0xB207101A),
                ],
                stops: [0, 0.29, 1],
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          child: _scene == null
              ? const SizedBox.shrink()
              : KeyedSubtree(
                  key: ValueKey('${_scene!.name}-${_progress.era.name}'),
                  child: _sceneView(_scene!),
                ),
        ),
        _header(),
        if (!_past && _progress.metMio) _inventory(),
        // Once fitted into the door, the watch is no longer in hand.
        if (!_doorWatchIn) _watchButton(),
        if ((_focus != null || _scene != null) &&
            _panel == null &&
            _dialogue.isEmpty)
          _backButton(),
        if (_timeFlash)
          const IgnorePointer(child: ColoredBox(color: Color(0x9AFFF4CF))),
        if (_panel != null) _modal(),
        if (_dialogue.isNotEmpty)
          DialoguePanel(
            key: ValueKey(_dialogueIndex),
            line: _dialogue[_dialogueIndex],
            onNext: _advanceDialogue,
            largeText: _largeText,
          ),
      ],
    );
  }

  /// Everything painted in stage coordinates, so the close-up camera moves
  /// the room, its overlays and its tap targets together.
  List<Widget> _world() {
    return [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        child: const bool.fromEnvironment('MIO_NO_ASSETS')
            ? _fallbackRoom()
            : Image.asset(
                _past
                    ? 'assets/images/room_1926.png'
                    : 'assets/images/room_2126.png',
                key: ValueKey(_progress.era),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, error, stack) => _fallbackRoom(),
              ),
      ),
      if (!const bool.fromEnvironment('MIO_NO_ASSETS')) ...[
        _closeUpPainting(),
        for (final patch in _roomPatches) _patch(patch),
      ],
      ..._visualOverlays(),
      for (final def in roomHotspots)
        if (_visible(def) && _beckons(def)) _outlineGlow(def),
      for (final def in roomHotspots)
        if (_visible(def)) _hotspot(def),
    ];
  }

  /// The detailed painting of the spot the camera walked up to. It fades in
  /// as the camera closes in, fades out as it steps back, and simply stays
  /// hidden if the file is missing.
  Widget _closeUpPainting() {
    final zone = _lastFocus;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _focus == null ? 0 : 1,
          duration: _zoomDuration,
          child: zone == null || !zone.painted
              ? const SizedBox.expand()
              : Stack(
                  children: [
                    Positioned.fromRect(
                      rect: zone.camera,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 650),
                        child: Image.asset(
                          zone.asset(_past),
                          key: ValueKey('${zone.id}-${_progress.era}'),
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, error, stack) =>
                              const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _workbenchScene() {
    final frame = _tinFrames == null || _dialogue.isEmpty
        ? null
        : _tinFrames![_dialogueIndex.clamp(0, _tinFrames!.length - 1)];
    return WorkbenchScene(
      past: _past,
      showGear: frame?.$2 ?? (_past && !_progress.gearInTin),
      tin:
          frame?.$1 ??
          (_past
              ? TinLook.closed1926
              : !_progress.gearInTin
              ? TinLook.none
              : _progress.tinOpened
              ? TinLook.open2026
              : TinLook.sealed2026),
      gearHighlighted: _progress.metMio && frame == null,
      tinHighlighted:
          frame == null &&
          (_past
              ? _progress.flag('gearSeen') && !_progress.gearInTin
              : !_progress.tinOpened),
      onGear: _sceneGear,
      onTin: _sceneTin,
    );
  }

  Widget _sceneView(_Scene scene) {
    return switch (scene) {
      _Scene.workbench => _workbenchScene(),
      _Scene.lock => LockScene(
        layout: drawerLock,
        digits: _drawerDigits,
        onDigit: (index, delta) =>
            _turnWheel(_drawerDigits, index, delta, _unlockDrawer),
      ),
      _Scene.boxLock => LockScene(
        layout: boxLock,
        digits: _boxDigits,
        onDigit: (index, delta) =>
            _turnWheel(_boxDigits, index, delta, _unlockBox),
      ),
      _Scene.baseLock => LockScene(
        layout: baseLock,
        digits: _baseDigits,
        onDigit: (index, delta) =>
            _turnWheel(_baseDigits, index, delta, _unlockBase),
      ),
      _Scene.baseOpen => BaseDrawerScene(
        showOil: !_progress.oilTaken,
        onOil: _sceneOil,
      ),
      _Scene.calendar => const CalendarScene(),
      _Scene.newspaper => const NewspaperScene(
        headline: newspaperHeadline,
        body: newspaperBody,
      ),
      _Scene.pillar => PillarScene(past: _past, marks: _heightMarks),
      _Scene.door => DoorScene(
        glowing: _progress.clockRunning,
        watchIn: _doorWatchIn,
      ),
    };
  }

  Widget _backButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 26,
      child: Center(
        child: Semantics(
          label: '部屋全体に戻る',
          button: true,
          child: GestureDetector(
            key: const Key('step-back'),
            onTap: _stepBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              decoration: _glassDecoration(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_down, color: _gold, size: 34),
                  SizedBox(width: 6),
                  Text(
                    'もどる',
                    style: TextStyle(
                      color: _paper,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackRoom() {
    return Container(
      key: ValueKey(_progress.era),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _past
              ? const [Color(0xFF9E7141), Color(0xFF47301D)]
              : const [Color(0xFF162A3C), Color(0xFF060E19)],
        ),
      ),
      child: const Center(
        child: Text(
          '時任時計店の書斎',
          style: TextStyle(
            color: Color(0xFFE8BF79),
            fontSize: 47,
            letterSpacing: 8,
          ),
        ),
      ),
    );
  }

  bool _visible(HotspotDef def) {
    if (_past && !def.past || !_past && !def.future) return false;
    if (def.id == 'tin' && !_past && !_progress.gearInTin) return false;
    return true;
  }

  /// Whether a painted object is worth pointing at right now. Until Mio is
  /// met only the pocket watch beckons; items painted over the room (tin,
  /// gear) carry their own rim instead.
  bool _beckons(HotspotDef def) {
    final p = _progress;
    final gate = _gate;
    if (gate != null) return def.id == gate;
    return switch (def.id) {
      'calendar' => _past && !p.notes.contains('n_calendar'),
      'drawer' => !_past && !p.drawerOpened,
      'pillar' => !_past && p.heightMarked && !p.boxOpened,
      'chair' =>
        p.docs.contains('memo3') &&
            (_past
                ? !p.flag('favoritePlace')
                : p.flag('favoritePlace') && !p.chairSearched),
      'clockBase' => !_past && p.oilHidden && !p.oilTaken,
      'shelfBox' => !_past && p.heightMarked && !p.boxOpened,
      'blackboard' => !_past && p.flag('codeOnBoard') && !p.flag('boardFaded'),
      'window' => !_past && p.flag('codeOnWindow') && !p.flag('baseUnlocked'),
      'fireplace' =>
        p.inventory.contains('blankLetter') &&
            (_past ? !p.flag('inkTalk') : p.flag('inkTalk')),
      'newspaper' => !_past && !p.docs.contains('newspaper'),
      _ => false,
    };
  }

  /// A faint gold line traced along the painted object's own edge.
  Widget _outlineGlow(HotspotDef def) {
    return Positioned.fromRect(
      rect: glowOutlines[def.id] ?? def.bounds,
      child: const IgnorePointer(
        child: CustomPaint(painter: _EdgeGlowPainter()),
      ),
    );
  }

  Widget _hotspot(HotspotDef def) {
    return Positioned.fromRect(
      rect: def.bounds,
      child: Semantics(
        label: def.label,
        button: true,
        child: GestureDetector(
          key: Key('hotspot-${def.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _approach(def.id, () => _interact(def.id)),
          child: const bool.fromEnvironment('MIO_NO_ASSETS')
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: _gold.withValues(alpha: 0.55)),
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    def.label,
                    style: const TextStyle(color: _paper, fontSize: 19),
                  ),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }

  /// The room painting as the story has left it: Mio's marks on the pillar,
  /// and the clock's gear and pendulum once they are back.
  List<RoomPatch> get _roomPatches => [
    pillarPatch(past: _past, marked: _progress.heightMarked),
    if (!_past && _progress.fireLit) firePatch,
    if (!_past)
      _progress.clockPendulumInstalled
          ? clockPatchFull
          : _progress.clockGearInstalled
          ? clockPatchGear
          : clockPatchEmpty,
  ];

  Widget _patch(RoomPatch patch) => Positioned.fromRect(
    rect: patch.rect,
    child: IgnorePointer(
      child: Image.asset(
        patch.asset,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, error, stack) => const SizedBox.expand(),
      ),
    ),
  );

  List<Widget> _visualOverlays() {
    return [
      // Firelight spilling into the dark room.
      if (!_past && _progress.fireLit)
        const Positioned(
          left: 440,
          top: 200,
          width: 620,
          height: 520,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.25),
                  radius: 0.6,
                  colors: [Color(0x40FF9A3C), Color(0x00FF9A3C)],
                ),
              ),
            ),
          ),
        ),
      if (_past)
        Positioned.fromRect(
          rect: mioRect,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 210),
              child: Image.asset(
                _mioAsset,
                key: ValueKey(_mioAsset),
                fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => const Center(
                  child: Text(
                    'ミオ',
                    style: TextStyle(color: _paper, fontSize: 38),
                  ),
                ),
              ),
            ),
          ),
        ),
      // Mio's glass-cutter numbers on the surviving pane.
      if (!_past && _progress.flag('codeOnWindow'))
        Positioned.fromRect(
          rect: windowCodeRect,
          child: const IgnorePointer(
            child: FittedBox(
              child: Text(
                '275',
                style: TextStyle(
                  fontFamily: 'MioHand',
                  color: Color(0xB3E8F0FF),
                  letterSpacing: 2,
                  shadows: [Shadow(color: Color(0xCC0B1530), blurRadius: 2)],
                ),
              ),
            ),
          ),
        ),
      if (!_past && _progress.clockRunning)
        Positioned.fromRect(
          rect: doorRecessRect,
          child: const IgnorePointer(
            child: CustomPaint(painter: _EdgeGlowPainter(circle: true)),
          ),
        ),
    ];
  }

  Widget _header() {
    return Stack(
      children: [
        // Under the date, flush with the left edge so the boxes line up.
        Positioned(top: 96, left: 30, child: _taskList()),
        Positioned(
          left: 28,
          top: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: _glassDecoration(),
            child: Text(
              _past ? '1926年（大正十五年）4月13日  午後3時' : '2026年4月13日  深夜',
              style: const TextStyle(
                color: _paper,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 25,
          child: IgnorePointer(
            ignoring: _gate != null,
            child: AnimatedOpacity(
              opacity: _gate != null ? 0.35 : 1,
              duration: const Duration(milliseconds: 300),
              child: Row(
                children: [
                  _topButton('手紙', Icons.mail_outline, () {
                    setState(() {
                      _unreadNote = false;
                      _panel = _Panel.notebook;
                    });
                  }, unread: _unreadNote),
                  const SizedBox(width: 10),
                  _topButton('ヒント', Icons.lightbulb_outline, _showHint),
                  const SizedBox(width: 10),
                  _topButton('メニュー', Icons.menu, () {
                    setState(() {
                      _confirmReset = false;
                      _panel = _Panel.menu;
                    });
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// What the player wants to do next, in their own words, plus the clock
  /// parts still to gather. It never spells out a puzzle's answer.
  String get _currentWant {
    final p = _progress;
    final gate = _gate;
    if (!p.metMio) return '光る懐中時計を調べる';
    if (!p.flag('tourStarted')) return 'ミオの話を聞く';
    if (gate == 'clock' || gate == 'watch' && !p.flag('clockChecked')) {
      return '2026年の大時計を確認する';
    }
    if (gate != null) return 'ミオに大時計のことを知らせる';
    // Only what the player has actually come across; nothing found yet
    // means looking for the clock's parts.
    final has = p.inventory.contains;
    if (p.flag('drawerSeen') && !p.drawerOpened) return '机の引き出しの錠を開けたい';
    if (p.flag('gearSeen') && !p.gearInTin) return '歯車を百年後へ届けたい';
    if (p.gearInTin && !p.tinOpened) {
      return p.notes.contains('n_waxSeal')
          ? '缶の蝋をやわらかくしたい'
          : '2026年で、ミオの缶を受け取りたい';
    }
    if (p.tinOpened && !p.clockGearInstalled) return '歯車を大時計にはめたい';
    if (p.flag('boxLockSeen') && !p.boxOpened) {
      if (p.heightMarked) return '柱の印で、ミオの背がいちばん伸びた年を調べたい';
      return p.flag('measureAsked') ? 'ミオの背を測る場所を探したい' : 'ミオに背を測ってもらいたい';
    }
    if (has('blankLetter')) {
      return p.flag('inkTalk') ? '暖炉の火で、白紙の手紙をあぶりたい' : '白紙の手紙を読む方法を知りたい';
    }
    if (p.docs.contains('memo3') && !p.chairSearched) {
      return p.flag('favoritePlace') ? '椅子の下の床板を外したい' : 'ミオのいちばん好きな場所を知りたい';
    }
    if (has('pendulum')) return '振り子を大時計に吊るしたい';
    if (p.flag('springRusty') && !p.oilHidden) return '錆びたぜんまいをどうにかしたい';
    if (p.oilHidden && !p.flag('baseUnlocked')) {
      if (p.flag('codeOnWindow')) return '窓に刻まれた番号を確かめたい';
      if (p.flag('boardFaded')) return '消えた番号のことを、ミオに相談したい';
      return '台座の錠の番号を知りたい';
    }
    if (p.flag('baseUnlocked') && !p.oilTaken) return 'ミオの時計油を受け取りたい';
    if (has('oil')) return 'ぜんまいに時計油を差したい';
    if (p.clockGearInstalled &&
        p.clockPendulumInstalled &&
        !p.clockRunning &&
        (p.clockOiled || !p.flag('springRusty'))) {
      return '大時計のねじを巻きたい';
    }
    if (p.clockRunning) {
      if (p.flag('watchPromised')) return '扉を開けたい';
      return p.flag('doorRecessSeen') ? '扉のくぼみの正体を知りたい' : '扉を調べたい';
    }
    return '大時計の部品を探したい';
  }

  Widget _taskList() {
    final p = _progress;
    final parts = <(String, bool)>[
      ('歯車', p.inventory.contains('gear') || p.clockGearInstalled),
      ('振り子', p.inventory.contains('pendulum') || p.clockPendulumInstalled),
      ('ねじ巻き鍵', p.inventory.contains('windKey') || p.clockRunning),
      if (p.flag('springRusty'))
        ('時計油', p.inventory.contains('oil') || p.clockOiled),
    ];
    Widget row(String text, bool done, {bool lead = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_box : Icons.check_box_outline_blank,
            size: lead ? 20 : 17,
            color: done ? _gold.withValues(alpha: 0.6) : _gold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: done ? _paper.withValues(alpha: 0.55) : _paper,
                fontSize: lead ? 17 : 15,
                decoration: done ? TextDecoration.lineThrough : null,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4),
                  Shadow(color: Colors.black, blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _dialogue.isEmpty ? 1 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              row(_currentWant, false, lead: true),
              if (p.flag('tourDone'))
                for (final (name, done) in parts) row(name, done),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool unread = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 86,
        child: Center(
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _glassDecoration(),
            child: Row(
              children: [
                Icon(icon, color: _gold, size: 24),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(color: _paper, fontSize: 18),
                ),
                if (unread) ...[
                  const SizedBox(width: 7),
                  const Icon(Icons.circle, color: Color(0xFFC04C40), size: 9),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What the player carries in 2026. (In 1926 the see-through body holds
  /// nothing, so the slots are hidden there.)
  Widget _inventory() {
    final items = [
      for (final id in itemOrder)
        if (_progress.inventory.contains(id)) id,
    ];
    // Tucked away while someone is talking, so it never sits under the
    // dialogue window.
    return Positioned(
      left: 22,
      bottom: 18,
      child: IgnorePointer(
        ignoring: _dialogue.isNotEmpty,
        child: AnimatedOpacity(
          opacity: _dialogue.isEmpty ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              for (var index = 0; index < 5; index++)
                _slot(index < items.length ? items[index] : null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slot(String? item) {
    final selected = item != null && _selectedItem == item;
    return GestureDetector(
      key: item == null ? null : Key('item-$item'),
      onTap: item == null
          ? null
          : () => setState(() => _selectedItem = selected ? null : item),
      child: Container(
        width: 78,
        height: 78,
        margin: const EdgeInsets.only(right: 7),
        decoration: BoxDecoration(
          color: const Color(0xD8091C29),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFD174)
                : _gold.withValues(alpha: 0.5),
            width: selected ? 3 : 1.2,
          ),
        ),
        child: item == null
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/item_$item.png',
                    width: 44,
                    height: 44,
                    errorBuilder: (_, error, stack) =>
                        const Icon(Icons.help_outline, color: _gold, size: 32),
                  ),
                  Text(
                    itemNames[item]!,
                    style: const TextStyle(color: _paper, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _watchButton() {
    // Before the first jump the watch is the only thing worth touching, so
    // it pulses to show where to begin.
    final beckon = _dialogue.isEmpty && _panel == null && _gate == 'watch';
    return Positioned(
      right: 18,
      bottom: 10,
      child: Semantics(
        label: '懐中時計で時代を切り替える',
        button: true,
        child: GestureDetector(
          key: const Key('watch-button'),
          onTap: _travel,
          child: SizedBox(
            width: 128,
            height: 138,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 4,
                  width: 112,
                  height: 112,
                  child: _OutlinePulse(
                    active: beckon,
                    asset: 'assets/images/ui_pocketwatch.png',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: _glassDecoration(),
                    child: Text(
                      _past ? '2026年へ' : '1926年へ',
                      style: const TextStyle(color: _paper, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modal() {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _panel == _Panel.choice && _choiceRequired
                ? null
                : _closePanel,
            child: Container(color: const Color(0xCC020710)),
          ),
          Center(child: _panelContent()),
        ],
      ),
    );
  }

  Widget _panelContent() {
    switch (_panel!) {
      case _Panel.document:
        final id = _documentId!;
        if (LetterPanel.letterIds.contains(id)) {
          return LetterPanel(
            id: id,
            text: documentText(id, _progress),
            onClose: _closePanel,
          );
        }
        return DocumentPanel(id: id, progress: _progress, onClose: _closePanel);
      case _Panel.notebook:
        return LettersPanel(
          progress: _progress,
          onDocument: (id) => _showDocument(id, add: false),
          onClose: _closePanel,
        );
      case _Panel.hint:
        final stage = _progress.currentStage(widget.endings);
        return HintPanel(
          stage: stage,
          revealed: _progress.hintLevel[stage] ?? 0,
          loading: _hintLoading,
          message: _hintMessage,
          onWatch: _watchForHint,
          onClose: _closePanel,
        );
      case _Panel.menu:
        return MenuPanel(
          largeText: _largeText,
          soundOn: _soundOn,
          confirmReset: _confirmReset,
          onToggleText: () => setState(() => _largeText = !_largeText),
          onToggleSound: () {
            setState(() => _soundOn = !_soundOn);
            _audio.setEnabled(_soundOn);
            widget.onSoundChanged(_soundOn);
          },
          onTitle: widget.onTitle,
          onReset: () {
            if (_confirmReset) {
              widget.onRestart();
            } else {
              setState(() => _confirmReset = true);
            }
          },
          onClose: _closePanel,
        );
      case _Panel.choice:
        return ChoicePanel(
          title: _choiceTitle,
          description: _choiceDescription,
          choices: _choices,
          onChoose: (index) => _onChoice?.call(index),
          onClose: _closePanel,
        );
    }
  }

  BoxDecoration _glassDecoration() => BoxDecoration(
    color: const Color(0xDF071B27),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: _gold.withValues(alpha: 0.76), width: 1.5),
    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)],
  );
}

/// An image whose own silhouette glows gold and breathes while [active],
/// so the highlight follows the drawing's edge rather than a circle.
class _OutlinePulse extends StatefulWidget {
  const _OutlinePulse({required this.active, required this.asset});

  final bool active;
  final String asset;

  @override
  State<_OutlinePulse> createState() => _OutlinePulseState();
}

class _OutlinePulseState extends State<_OutlinePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_OutlinePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image({Color? tint}) => Image.asset(
      widget.asset,
      fit: BoxFit.contain,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcIn,
      errorBuilder: (_, error, stack) =>
          const Icon(Icons.watch_later_outlined, color: _gold, size: 64),
    );
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (widget.active)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              // A tight rim plus a wider breathing halo, both from the
              // drawing's own silhouette.
              return Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: 6 + 8 * t,
                      sigmaY: 6 + 8 * t,
                    ),
                    child: image(tint: _gold.withValues(alpha: 0.5 + 0.5 * t)),
                  ),
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: image(tint: const Color(0xFFFFE3A0)),
                  ),
                ],
              );
            },
          ),
        image(),
      ],
    );
  }
}

/// Traces the edge of a painted object with a thin gold line and a soft halo
/// that stays on the line, leaving the object itself unpainted.
class _EdgeGlowPainter extends CustomPainter {
  const _EdgeGlowPainter({this.circle = false});

  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    void stroke(Paint paint) => circle
        ? canvas.drawOval(rect, paint)
        : canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            paint,
          );
    stroke(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = _gold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    stroke(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _gold.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_EdgeGlowPainter oldDelegate) =>
      oldDelegate.circle != circle;
}
