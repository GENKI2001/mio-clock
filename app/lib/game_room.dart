import 'dart:async';

import 'package:flutter/material.dart';

import 'data/hotspots.dart';
import 'data/story_text.dart';
import 'game_progress.dart';
import 'puzzles/clock_cipher.dart';
import 'soundscape.dart';
import 'widgets/clock_glyph.dart';
import 'widgets/dialogue_panel.dart';
import 'widgets/door_dial.dart';
import 'widgets/meta_panels.dart';
import 'widgets/paper_panel.dart';
import 'widgets/puzzle_panels.dart';

const _gold = Color(0xFFE8BF79);
const _paper = Color(0xFFF3E6C8);
const _ink = Color(0xFF34291F);

enum _Panel {
  calendar,
  drawer,
  backLock,
  marks,
  blackboard,
  document,
  notebook,
  hint,
  menu,
  door,
  clockBase,
  choice,
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
  });

  final GameProgress progress;
  final Set<String> endings;
  final bool soundOn;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<GameProgress> onSave;
  final VoidCallback onTitle;
  final VoidCallback onRestart;
  final ValueChanged<String> onEnding;

  @override
  State<GameRoom> createState() => _GameRoomState();
}

class _GameRoomState extends State<GameRoom> {
  final Soundscape _audio = Soundscape();
  _Panel? _panel;
  String? _documentId;
  String? _lockError;
  String? _doorMessage;
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
  final List<int> _backDigits = [0, 0, 0, 0];
  final List<ClockGlyph> _doorInput = [];
  int _doorHour = 12;
  int _doorMinute = 12;
  bool _shortHand = true;
  bool _confirmHint = false;
  bool _confirmReset = false;
  bool _largeText = false;
  bool _soundOn = true;
  bool _unreadNote = false;
  bool _timeFlash = false;
  Timer? _flashTimer;

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
    if (!_progress.introSeen) {
      _progress.introSeen = true;
      _progress.notes.add('n_watchMT');
      widget.onSave(_progress);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final lines = widget.endings.isEmpty
            ? introLines
            : [introLines.first, introLines.last];
        _showDialogue(lines);
      });
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
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
      _afterDialogue = after;
    });
  }

  void _say(String text, [VoidCallback? after]) =>
      _showDialogue([DialogueLine(text)], after);

  void _advanceDialogue() {
    if (_dialogueIndex + 1 < _dialogue.length) {
      setState(() => _dialogueIndex++);
      return;
    }
    final after = _afterDialogue;
    setState(() {
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
      _lockError = null;
      _confirmHint = false;
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

  void _travel() {
    if (_panel != null || _dialogue.isNotEmpty) return;
    if (_past) {
      final held = _progress.holding1926;
      final count = _progress.farewellCount;
      final farewell = count == 0
          ? farewellLines.first
          : farewellLines[1 + (count - 1) % 4];
      _showDialogue([farewell], () {
        setState(() {
          _progress.travel();
          _selectedItem = null;
        });
        _persist();
        _audio.play('se_timeshift');
        _audio.setEra(_progress.era);
        _flash();
        if (held) {
          _say('持っていた歯車は時を越えられず、手の中から消えた。……振り返ると、作業台の上に戻っている気がした');
        }
      });
    } else {
      final firstVisit = !_progress.metMio;
      setState(() {
        _progress.travel();
        _selectedItem = null;
      });
      _persist();
      _audio.play('se_timeshift');
      _audio.setEra(_progress.era);
      _flash();
      if (firstVisit) {
        _showDialogue(meetOpening, () {
          _showChoice('ミオに答える', 'あなたはどう返事をする?', ['どうしてわかったの?', '2126年から来た'], (
            index,
          ) {
            final answer = index == 0
                ? const DialogueLine(
                    'お母様が言ってたの。この時計は、時をまたぐ時計なんだって。……おとぎ話だと思ってたけど!',
                    speaker: 'ミオ',
                    expression: 'proud',
                  )
                : const DialogueLine(
                    'ひゃ、百年後!? ……すごい、すごい!',
                    speaker: 'ミオ',
                    expression: 'surprise',
                  );
            _showDialogue([answer, ...meetClosing]);
          }, requiredChoice: true);
        });
      }
    }
  }

  void _interact(String id) {
    if (_panel != null || _dialogue.isNotEmpty) return;
    if (_past && _progress.holding1926) {
      final placement = switch (id) {
        'workbench' => GearSpot.workbench,
        'windowsill' => GearSpot.windowsill,
        'desk' => GearSpot.desk,
        'fireplace' => GearSpot.fireplace,
        'tin' => GearSpot.tin,
        _ => null,
      };
      if (placement != null) {
        _placeGear(placement);
      } else {
        _say('ここには置けない');
      }
      return;
    }
    if (!_past && _selectedItem != null) {
      _useSelectedItem(id);
      return;
    }
    switch (id) {
      case 'clock':
        _clock();
      case 'clockBase':
        _note('n_example');
        setState(() => _panel = _Panel.clockBase);
      case 'pillar':
        _pillar();
      case 'calendar':
        _calendar();
      case 'drawer':
        _drawer();
      case 'tin':
        _showDialogue(const [
          DialogueLine(
            '私の宝物缶。ふたを蝋で封じてあるから、百年だって平気よ。……中身は、ないしょ',
            speaker: 'ミオ',
            expression: 'proud',
          ),
        ]);
      case 'niche':
        _niche();
      case 'blackboard':
        _blackboard();
      case 'chair':
        _chair();
      case 'newspaper':
        _showDocument('newspaper');
      case 'door':
        _door();
      case 'mio':
        _mio();
      case 'window':
        _say(
          _past
              ? '窓の外に下町の瓦屋根。どこかで豆腐屋のラッパが鳴っている。'
              : '割れた窓の向こうに、光る高層の街並み。百年後の夜景だ。',
        );
      case 'windowsill':
        _windowsill();
      case 'workbench':
        _workbench();
      case 'fireplace':
        _fireplace();
      case 'desk':
        _desk();
      default:
        _say('何も見つからない。');
    }
  }

  void _calendar() {
    if (!_past) {
      _say('壁に錆びた釘が一本。何かが掛けてあった跡だけが、日焼けせずに四角く残っている。');
      return;
    }
    _note('n_calendar');
    setState(() => _panel = _Panel.calendar);
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
      _say(
        '引き出しに真鍮のダイヤル錠がついている。3桁だ。錠の上には「たいせつな ひ」。',
        () => setState(() => _panel = _Panel.drawer),
      );
    }
  }

  void _unlockDrawer() {
    if (_progress.tryOpenDrawer(_drawerDigits)) {
      _audio.play('se_unlock');
      _persist();
      _showDialogue(const [
        DialogueLine('錠が外れた。'),
        DialogueLine('引き出しの中には、真鍮のねじ巻き鍵と、黄ばんだ封筒が入っている。'),
      ], () => _showDocument('memo1', add: false));
    } else {
      _audio.play('se_locked');
      setState(() => _lockError = '開かない');
    }
  }

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
    if (!_progress.clockGearInstalled) {
      _note('n_missingGear');
      _say(
        '止まった大時計。文字盤の下の小窓が開いていて、中の歯車が一枚だけ抜けている。ぽっかり空いた軸に、ちょうど手のひらくらいの歯車が収まりそうだ。',
      );
    } else if (!_progress.backPanelOpened) {
      _note('n_backPanelLock');
      _say(
        '大時計の側面に、背面の扉を留める真鍮の錠がある。「ミオの背が、前の年から いちばん伸びた年を 西暦で」',
        () => setState(() => _panel = _Panel.backLock),
      );
    } else if (!_progress.clockPendulumInstalled) {
      _say('背面の扉は開いている。振り子を吊るす金具が空っぽだ。……ガラスの奥で、何かが動いた気がした。');
    } else if (!_progress.clockRunning) {
      _say('部品は揃った。あとはねじを巻くだけだ。');
    } else {
      _say('大時計が、ちくたくと時を刻んでいる。');
    }
  }

  void _unlockBackPanel() {
    if (_progress.tryOpenBackPanel(_backDigits)) {
      _audio.play('se_unlock');
      _persist();
      _showDialogue(const [
        DialogueLine('背面の扉が開いた。振り子を吊るす金具が空っぽのまま揺れている。'),
        DialogueLine('扉の内側に、折りたたまれた紙がピンで留めてある。'),
      ], () => _showDocument('memo3', add: false));
    } else {
      _audio.play('se_locked');
      setState(() {
        _lockError = _backDigits.join() == '1927'
            ? '開かない。……印の年を、もう一度数えなおしたほうがよさそうだ'
            : '開かない';
      });
    }
  }

  void _pillar() {
    if (_past) {
      if (_progress.heightMarked) {
        _say('「大正十五 一四二」と刻まれた真新しい印が一本。');
      } else {
        _showChoice(
          '背比べの柱',
          'ミオ「あ、その柱! 背比べの柱にしようと思ってたの。今日で14歳になったんだから、記念に測って!」',
          ['測ってあげる', 'あとで'],
          (index) {
            if (index == 0) {
              _audio.play('se_carve');
              setState(() => _progress.heightMarked = true);
              _note('n_heightStart');
              _showDialogue(const [
                DialogueLine('……かかとが浮いている'),
                DialogueLine(
                  'う、浮いてないもん!',
                  speaker: 'ミオ',
                  expression: 'embarrassed',
                ),
                DialogueLine(
                  '大正十五年、百四十二センチ……っと。えへへ',
                  speaker: 'ミオ',
                  expression: 'smile',
                ),
                DialogueLine(
                  'これから毎年、誕生日に測るんだ。百年後の柱が、印でいっぱいになるくらい!',
                  speaker: 'ミオ',
                  expression: 'smile',
                ),
              ]);
            } else {
              _showDialogue(const [
                DialogueLine(
                  'むぅ。背比べ、したかったのに',
                  speaker: 'ミオ',
                  expression: 'sad',
                ),
              ]);
            }
          },
        );
      }
    } else if (!_progress.heightMarked) {
      _say('古い柱。傷ひとつない。');
    } else {
      _note('n_pillar');
      setState(() => _panel = _Panel.marks);
    }
  }

  void _blackboard() {
    if (!_past) {
      _say('黒板はほとんどかすれて白い。「ミオ式」の三文字だけがかろうじて読める。');
      return;
    }
    final first = !_progress.cipherLearned;
    setState(() => _progress.cipherLearned = true);
    _note('n_cipher');
    _note('n_example');
    if (first) {
      _showDialogue(const [
        DialogueLine(
          'それ、私が考えた時計暗号! お父様にも内緒の',
          speaker: 'ミオ',
          expression: 'proud',
        ),
        DialogueLine(
          'みじかい針が「行」で、ながい針が「段」。ながい針は、何分かじゃなくて、指してる数字を見るの',
          speaker: 'ミオ',
        ),
        DialogueLine(
          '……れいの答え? な、ないしょ! 解いてもいいけど、口に出しちゃだめだからね',
          speaker: 'ミオ',
          expression: 'embarrassed',
        ),
      ], () => setState(() => _panel = _Panel.blackboard));
    } else {
      setState(() => _panel = _Panel.blackboard);
    }
  }

  void _chair() {
    if (_progress.chairSearched) {
      _say('外した床板の下は空っぽだ。');
    } else if (_progress.searchChair()) {
      _persist();
      _showDialogue(const [
        DialogueLine('脚の折れた椅子。……椅子の真下の床板だけ、釘が打たれていない。'),
        DialogueLine('床板を外すと、油布にくるまれた真鍮の振り子と、手紙が一通。'),
      ], () => _showDocument('memo4', add: false));
    } else {
      _say('脚の折れた椅子。……椅子の真下の床板だけ、釘が打たれていない。気にはなるが、今はどうにもできない。');
    }
  }

  void _niche() {
    if (_progress.tinOpened2126) {
      _say('空になった缶が穴の奥に残っている。');
    } else if (_progress.collectGear()) {
      _audio.play('se_unlock');
      _persist();
      _showDialogue(const [
        DialogueLine('レンガが一つ抜けた穴の奥に、錆びた缶。ふたの縁が、固まった蝋で封じられている。'),
        DialogueLine('蝋を爪で剥がしてふたを開けると――油紙にくるまれた真鍮の歯車が、百年前と同じ輝きで入っていた。'),
      ], () => _showDocument('memo2', add: false));
    }
  }

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
    if (_progress.clockRunning) {
      setState(() {
        _doorMessage = null;
        _panel = _Panel.door;
      });
    } else {
      _say('鍵穴のない扉。中央に、時計の文字盤の浮き彫りがある。針は動かない。文字盤の縁には「約束の言葉を、時の針で」。');
    }
  }

  void _windowsill() {
    if (_past) {
      _say('植木鉢に小さな花。陽だまりがあたたかい。');
    } else if (_progress.gearSpot == GearSpot.windowsill) {
      _say('窓辺に、緑青に覆われた塊がこびりついている。……歯車だったものだ。歯がぼろぼろに欠けていて、とても使えない。');
    } else {
      _say('雨だれの跡が黒く染みている。');
    }
  }

  void _workbench() {
    if (_past) {
      _say(
        _progress.gearSpot == GearSpot.workbench
            ? '工具、ルーペ、真鍮の削りくず。予備の歯車が置いてある。'
            : '工具、ルーペ、真鍮の削りくず。',
      );
    } else {
      _say('作業台は朽ちて天板が抜け落ちている。何も残っていない。');
    }
  }

  void _fireplace() {
    if (_past) {
      _say('春なので火は入っていない。煤のにおい。');
    } else if (_progress.gearSpot == GearSpot.fireplace) {
      _say('暖炉の奥に、煤で真っ黒に固まった歯車があった。軸穴まで埋まっていて、使いものにならない。');
    } else {
      _say('崩れかけた暖炉。');
    }
  }

  void _desk() {
    if (_past) {
      _say('父親の机。設計図が広げてある。「百年時計 図面 其ノ三」');
    } else if (_progress.gearSpot == GearSpot.desk) {
      _say('机の上には厚い埃。……歯車は見当たらない。百年のあいだに誰かが持ち去ったのかもしれない。');
    } else {
      _say('埃に覆われた机。引き出しには真鍮の錠がついている。');
    }
  }

  void _pickGear() {
    if (_progress.pickGear()) {
      final first = _progress.flags['gearTalk'] != true;
      _progress.flags['gearTalk'] = true;
      _persist();
      _showDialogue([
        if (first)
          const DialogueLine(
            'それ、私が削った予備の歯車! 百年時計の心臓なんだから',
            speaker: 'ミオ',
            expression: 'proud',
          ),
        const DialogueLine('歯車を手に取った。……触れられる。この歯車だけは、なぜか'),
      ]);
    }
  }

  void _placeGear(GearSpot spot) {
    if (!_progress.placeGear(spot)) return;
    _audio.play('se_gear', volume: 0.4);
    _persist();
    if (spot == GearSpot.tin) {
      _showDialogue(const [
        DialogueLine(
          'わっ、私の宝物缶に? ……そっか、百年もたせたいのね',
          speaker: 'ミオ',
          expression: 'surprise',
        ),
        DialogueLine(
          'この缶はね、ふたを蝋で封じてあるの。水も虫も入らない。それに、しまう場所だって特別なんだから',
          speaker: 'ミオ',
          expression: 'proud',
        ),
        DialogueLine(
          '見てて。……暖炉の横のレンガ、ひとつだけ外れるの。おばあさまの代からの、ひみつの隠し棚!',
          speaker: 'ミオ',
          expression: 'smile',
        ),
        DialogueLine(
          '百年後のあなたに届くように。……ちくたく、ちくたく。はい、おまじない',
          speaker: 'ミオ',
          expression: 'smile',
        ),
      ]);
      return;
    }
    final line = switch (spot) {
      GearSpot.workbench => '歯車を作業台に戻した。',
      GearSpot.windowsill => '歯車を窓辺に置いた。陽の光がきらきらと反射している。',
      GearSpot.desk => '歯車を机の上に置いた。',
      GearSpot.fireplace => '歯車を暖炉の奥に置いた。',
      GearSpot.tin => '',
    };
    _say(line);
  }

  void _useSelectedItem(String id) {
    final item = _selectedItem;
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
        if (!_progress.backPanelOpened) {
          _say('振り子を吊るす場所が見当たらない。');
        } else if (_progress.installPendulum()) {
          _audio.play('se_gear');
          _persist();
          _say('振り子を金具に吊るした。');
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
        } else {
          _say('鍵を差してねじを巻いてみたが、ぜんまいが空回りするだけだ。まだ何かが足りない。');
        }
      default:
        _say('ここでは使えないようだ。');
    }
  }

  void _mio() {
    final topics = <String>[
      '百年時計のこと',
      'その懐中時計',
      '百年後のこと',
      if (_progress.cipherLearned) '好きな言葉',
      if (_progress.flags['gearHeld'] == true &&
          _progress.gearSpot != GearSpot.tin)
        '歯車の隠し場所',
      if (_progress.heightMarked) '柱の印',
      if (_progress.docs.contains('newspaper')) '新聞のこと',
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
            DialogueLine('……私も、いつか跳べるのかな', speaker: 'ミオ', expression: 'sad'),
          ]);
        case '百年後のこと':
          _showDialogue(const [
            DialogueLine('百年後、この部屋には誰もいないの? ……さみしいね', speaker: 'ミオ'),
            DialogueLine('でも、今日はあなたがいる!', speaker: 'ミオ', expression: 'smile'),
          ]);
        case '好きな言葉':
          _showDialogue(const [
            DialogueLine(
              '黒板のれいのこと? ……ないしょって言ったでしょ!',
              speaker: 'ミオ',
              expression: 'embarrassed',
            ),
            DialogueLine(
              'お父様が帰ってきたときに、いつも言う言葉。それだけ教えてあげる',
              speaker: 'ミオ',
              expression: 'smile',
            ),
          ]);
        case '歯車の隠し場所':
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
        case '新聞のこと':
          _showDialogue(const [
            DialogueLine('新聞のことは、言えなかった'),
            DialogueLine('? どうしたの、変な顔', speaker: 'ミオ'),
          ]);
        case 'ヒントがほしい':
          _showHint();
        default:
          _closePanel();
      }
    });
  }

  void _showHint() {
    final stage = _progress.currentStage(widget.endings);
    if ((_progress.hintLevel[stage] ?? 0) == 0) {
      _progress.revealHint(stage);
      _persist();
    }
    setState(() {
      _confirmHint = false;
      _panel = _Panel.hint;
    });
  }

  void _moreHint() {
    final stage = _progress.currentStage(widget.endings);
    if ((_progress.hintLevel[stage] ?? 0) == 2 && !_confirmHint) {
      setState(() => _confirmHint = true);
      return;
    }
    setState(() {
      _progress.revealHint(stage);
      _confirmHint = false;
    });
    _persist();
  }

  void _stampGlyph() {
    if (_doorInput.length >= 6) {
      setState(() => _doorMessage = '六文字まで刻める。');
      return;
    }
    final glyph = ClockGlyph(_doorHour, _doorMinute);
    if (decodeClock(glyph) == null) {
      setState(() => _doorMessage = 'その時刻は、言葉にならないようだ。');
      return;
    }
    setState(() {
      _doorInput.add(glyph);
      _doorMessage = null;
    });
  }

  void _sayDoorWord() {
    if (_doorInput.isEmpty) return;
    final answer = decodeSequence(_doorInput);
    if (answer == 'またね') {
      _audio.play('se_door');
      widget.onEnding('normal');
    } else if (answer == 'おかえり') {
      _audio.play('se_door');
      widget.onEnding('true');
    } else {
      setState(() {
        _doorMessage = switch (answer) {
          'さよなら' => '文字盤が冷たく沈黙した。……ミオが、いちばん嫌っていた言葉だ',
          'みお' => '文字盤の奥で、何かが応えかけて――また静かになった。名前だけでは、届かないらしい',
          _ => '扉は沈黙している',
        };
      });
    }
  }

  void _changeDigit(List<int> digits, int index, int delta) {
    setState(() {
      digits[index] = (digits[index] + delta + 10) % 10;
      _lockError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
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
                  errorBuilder: (_, error, stack) => _fallbackRoom(),
                ),
        ),
        const DecoratedBox(
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
        ..._visualOverlays(),
        for (final def in roomHotspots)
          if (_visible(def)) _hotspot(def),
        if (_past &&
            !_progress.holding1926 &&
            _progress.gearSpot != GearSpot.tin)
          _gearHotspot(),
        _header(),
        _inventory(),
        _watchButton(),
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
    if (def.id == 'tin' && _progress.nicheRevealed) return false;
    if (def.id == 'niche' && !_progress.nicheRevealed) return false;
    return true;
  }

  Widget _hotspot(HotspotDef def) {
    final glint = switch (def.id) {
      'calendar' => _past && !_progress.notes.contains('n_calendar'),
      'drawer' => !_past && !_progress.drawerOpened,
      'tin' => _past && _progress.holding1926,
      'niche' => !_past && !_progress.tinOpened2126,
      'pillar' =>
        _past &&
            !_progress.heightMarked &&
            _progress.currentStage(widget.endings) == 's3',
      'blackboard' =>
        _past &&
            !_progress.cipherLearned &&
            _progress.currentStage(widget.endings) == 's4',
      'chair' =>
        !_past &&
            _progress.docs.contains('memo3') &&
            _progress.cipherLearned &&
            !_progress.chairSearched,
      'door' => !_past && _progress.clockRunning,
      _ => false,
    };
    return Positioned.fromRect(
      rect: def.bounds,
      child: Semantics(
        label: def.label,
        button: true,
        child: GestureDetector(
          key: Key('hotspot-${def.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _interact(def.id),
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
              : glint
              ? Align(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withValues(alpha: 0.3),
                      border: Border.all(color: _paper, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: _gold,
                          blurRadius: 18,
                          spreadRadius: 7,
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _gearHotspot() {
    final position = gearPositions[_progress.gearSpot.name]!;
    return Positioned(
      left: position.dx - 45,
      top: position.dy - 40,
      width: 90,
      height: 80,
      child: Semantics(
        label: '予備の歯車',
        button: true,
        child: GestureDetector(
          key: const Key('gear-hotspot'),
          behavior: HitTestBehavior.opaque,
          onTap: _pickGear,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0xB7E6A653), blurRadius: 13),
              ],
            ),
            child: Image.asset(
              'assets/images/item_gear.png',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stack) =>
                  const Icon(Icons.settings, color: _gold, size: 38),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _visualOverlays() {
    return [
      if (_past)
        Positioned(
          left: 1010,
          top: 205,
          width: 178,
          height: 500,
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
      if (_past && !_progress.nicheRevealed)
        Positioned(
          left: 535,
          top: 351,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/item_tin.png',
              width: 70,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stack) => const Icon(
                Icons.inventory_2_outlined,
                color: _gold,
                size: 30,
              ),
            ),
          ),
        ),
      if (!_past)
        Positioned(
          left: 1070,
          top: 178,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.06,
              child: Container(
                width: 78,
                height: 89,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFCEA9),
                  border: Border.all(color: const Color(0xFF8C7457), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 7),
                  ],
                ),
                child: Column(
                  children: [
                    Container(width: 49, height: 5, color: _ink),
                    const SizedBox(height: 8),
                    for (var index = 0; index < 6; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Container(
                          width: index.isEven ? 54 : 41,
                          height: 2,
                          color: _ink.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (!_past && _progress.nicheRevealed)
        Positioned(
          left: 828,
          top: 344,
          child: IgnorePointer(
            child: Container(
              width: 54,
              height: 61,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xEE15110D),
                border: Border.all(color: const Color(0xFF9C7761), width: 4),
                boxShadow: const [BoxShadow(color: _gold, blurRadius: 7)],
              ),
              child: !_progress.tinOpened2126
                  ? Image.asset(
                      'assets/images/item_tin.png',
                      width: 45,
                      height: 38,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) => const Icon(
                        Icons.inventory_2_outlined,
                        color: _gold,
                        size: 27,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      if (!_past &&
          (_progress.gearSpot == GearSpot.windowsill ||
              _progress.gearSpot == GearSpot.fireplace))
        Positioned(
          left: _progress.gearSpot == GearSpot.windowsill ? 465 : 705,
          top: _progress.gearSpot == GearSpot.windowsill ? 341 : 447,
          child: IgnorePointer(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF718571),
                BlendMode.modulate,
              ),
              child: Image.asset(
                'assets/images/item_gear.png',
                width: 43,
                height: 43,
                errorBuilder: (_, error, stack) => const Icon(
                  Icons.settings,
                  size: 43,
                  color: Color(0xFF70826D),
                ),
              ),
            ),
          ),
        ),
      if (_progress.heightMarked)
        Positioned(
          left: 205,
          top: _past ? 334 : 276,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < (_past ? 1 : 5); index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 17),
                    child: Container(width: 20, height: 3, color: _gold),
                  ),
              ],
            ),
          ),
        ),
      if (!_past && _progress.clockGearInstalled)
        Positioned(
          left: 71,
          top: 329,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/item_gear.png',
              width: 32,
              height: 32,
              errorBuilder: (_, error, stack) =>
                  const Icon(Icons.settings, color: _gold, size: 31),
            ),
          ),
        ),
      if (!_past && _progress.clockRunning)
        Positioned(
          left: 69,
          top: 132,
          child: IgnorePointer(
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xCCEFC36A),
                    blurRadius: 46,
                    spreadRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      if (!_past)
        Positioned(
          right: 58,
          top: 273,
          child: IgnorePointer(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _progress.clockRunning
                      ? _gold
                      : const Color(0xFF766B5D),
                  width: 3,
                ),
                boxShadow: _progress.clockRunning
                    ? const [
                        BoxShadow(
                          color: _gold,
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: ClockGlyphView(
                  glyph: const ClockGlyph(12, 12),
                  size: 68,
                  face: _progress.clockRunning
                      ? const Color(0xFF4E321C)
                      : const Color(0xFF353230),
                  ink: _progress.clockRunning ? _gold : const Color(0xFF8A8074),
                  accent: _progress.clockRunning
                      ? _gold
                      : const Color(0xFF8A8074),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _header() {
    return Stack(
      children: [
        Positioned(
          left: 28,
          top: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: _glassDecoration(),
            child: Text(
              _past ? '1926年（大正十五年）4月13日  午後3時' : '2126年4月13日  深夜',
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
          child: Row(
            children: [
              _topButton('手帳', Icons.menu_book_outlined, () {
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
      ],
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

  Widget _inventory() {
    final items = _past
        ? (_progress.holding1926 ? <String>['holdingGear'] : <String>[])
        : [
            for (final id in ['windKey', 'gear', 'pendulum'])
              if (_progress.inventory.contains(id)) id,
          ];
    return Positioned(
      left: 26,
      bottom: 22,
      child: Row(
        children: List.generate(4, (index) {
          final item = index < items.length ? items[index] : null;
          final selected = item != null && _selectedItem == item;
          return GestureDetector(
            onTap: item == null || _past
                ? null
                : () => setState(() {
                    _selectedItem = selected ? null : item;
                  }),
            child: Container(
              width: 86,
              height: 86,
              margin: const EdgeInsets.only(right: 9),
              decoration: BoxDecoration(
                color: const Color(0xE0091C29),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFFD174)
                      : _gold.withValues(alpha: 0.7),
                  width: selected ? 3 : 1.4,
                ),
              ),
              child: item == null
                  ? null
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item == 'gear' || item == 'holdingGear')
                          Image.asset(
                            'assets/images/item_gear.png',
                            width: 40,
                            height: 40,
                            errorBuilder: (_, error, stack) => const Icon(
                              Icons.settings,
                              color: _gold,
                              size: 33,
                            ),
                          )
                        else
                          Icon(
                            item == 'windKey' ? Icons.key : Icons.access_time,
                            color: _gold,
                            size: 33,
                          ),
                        Text(switch (item) {
                          'windKey' => '鍵',
                          'gear' || 'holdingGear' => '歯車',
                          _ => '振り子',
                        }, style: const TextStyle(color: _paper, fontSize: 13)),
                      ],
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _watchButton() {
    return Positioned(
      right: 25,
      bottom: 18,
      child: Semantics(
        label: '懐中時計で時代を切り替える',
        button: true,
        child: GestureDetector(
          key: const Key('watch-button'),
          onTap: _travel,
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xEE392613),
              border: Border.all(color: _gold, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0xAA000000), blurRadius: 16),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.watch_later_outlined, color: _gold, size: 47),
                Text(
                  _past ? '2126へ' : '1926へ',
                  style: const TextStyle(color: _paper, fontSize: 15),
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
      case _Panel.calendar:
        return CalendarPanel(onClose: _closePanel);
      case _Panel.drawer:
        return NumberLockPanel(
          title: '真鍮のダイヤル錠',
          inscription: 'たいせつな ひ',
          digits: _drawerDigits,
          error: _lockError,
          onDigit: (index, delta) => _changeDigit(_drawerDigits, index, delta),
          onOpen: _unlockDrawer,
          onClose: _closePanel,
        );
      case _Panel.backLock:
        return NumberLockPanel(
          title: '大時計の背面の錠',
          inscription: 'ミオの背が、前の年から いちばん伸びた年を 西暦で',
          digits: _backDigits,
          error: _lockError,
          onDigit: (index, delta) => _changeDigit(_backDigits, index, delta),
          onOpen: _unlockBackPanel,
          onClose: _closePanel,
        );
      case _Panel.marks:
        return HeightMarksPanel(onClose: _closePanel);
      case _Panel.blackboard:
        return BlackboardPanel(onClose: _closePanel);
      case _Panel.document:
        return DocumentPanel(
          id: _documentId!,
          progress: _progress,
          onClose: _closePanel,
        );
      case _Panel.notebook:
        return NotebookPanel(
          progress: _progress,
          onDocument: (id) => _showDocument(id, add: false),
          onClose: _closePanel,
        );
      case _Panel.hint:
        final stage = _progress.currentStage(widget.endings);
        return HintPanel(
          stage: stage,
          level: _progress.hintLevel[stage] ?? 1,
          confirmAnswer: _confirmHint,
          past: _past,
          onMore: _moreHint,
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
      case _Panel.door:
        return PaperPanel(
          title: '扉の文字盤',
          width: 1010,
          onClose: _closePanel,
          child: DoorDial(
            hour: _doorHour,
            minuteMark: _doorMinute,
            shortHandActive: _shortHand,
            glyphs: _doorInput,
            message: _doorMessage,
            onSelectHand: (short) => setState(() => _shortHand = short),
            onSetNumber: (number) => setState(() {
              if (_shortHand) {
                _doorHour = number;
              } else {
                _doorMinute = number;
              }
            }),
            onStamp: _stampGlyph,
            onErase: () => setState(() {
              if (_doorInput.isNotEmpty) _doorInput.removeLast();
              _doorMessage = null;
            }),
            onSay: _sayDoorWord,
          ),
        );
      case _Panel.clockBase:
        return ClockBasePanel(onClose: _closePanel);
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
