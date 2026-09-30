import 'package:flutter/material.dart';

import 'game_progress.dart';

const _gold = Color(0xFFE8BF79);
const _paper = Color(0xFFF3E6C8);
const _ink = Color(0xFF34291F);

enum _Panel { calendar, drawer, notebook, hint, letter }

class GameRoom extends StatefulWidget {
  const GameRoom({
    super.key,
    required this.progress,
    required this.onSave,
    required this.onTitle,
  });

  final GameProgress progress;
  final ValueChanged<GameProgress> onSave;
  final VoidCallback onTitle;

  @override
  State<GameRoom> createState() => _GameRoomState();
}

class _GameRoomState extends State<GameRoom> {
  _Panel? _panel;
  String? _message = '懐中時計がかすかに震えている。竜頭を押してみよう。';
  final List<int> _digits = [0, 0, 0];
  bool _wrongCode = false;

  GameProgress get _progress => widget.progress;
  bool get _past => _progress.era == Era.past;

  void _persist() => widget.onSave(_progress);

  void _travel() {
    if (_panel != null) return;
    final firstVisit = !_progress.metMio && !_past;
    setState(() {
      _progress.travel();
      _message = firstVisit
          ? 'ミオ「……幽霊さん？ ちがう、未来のお客さま！」'
          : _past
          ? '百年後の書斎に戻った。ここは静かで、時計も止まっている。'
          : 'ミオ「またね！」 陽だまりの工房に戻った。';
    });
    _persist();
  }

  void _calendar() {
    if (!_past) {
      setState(() {
        _message = '壁に錆びた釘が一本。何かが掛けてあった跡だけが、日焼けせずに四角く残っている。';
      });
      return;
    }
    setState(() {
      _progress.calendarSeen = true;
      _message = null;
      _panel = _Panel.calendar;
    });
    _persist();
  }

  void _drawer() {
    if (_past) {
      setState(() {
        _message = '引き出しは半開きだ。中に真鍮のねじ巻き鍵が入っている。ミオ「それはお父様の大事なねじ巻き鍵。さわっちゃだめ！」';
      });
    } else if (_progress.drawerOpened) {
      setState(() => _message = '空っぽの引き出し。');
    } else {
      setState(() {
        _message = null;
        _wrongCode = false;
        _panel = _Panel.drawer;
      });
    }
  }

  void _setDigit(int index, int delta) {
    setState(() {
      _digits[index] = (_digits[index] + delta + 10) % 10;
      _wrongCode = false;
    });
  }

  void _openDrawer() {
    if (_progress.tryOpenDrawer(_digits)) {
      setState(() {
        _progress.memoRead = true;
        _panel = _Panel.letter;
      });
      _persist();
    } else {
      setState(() => _wrongCode = true);
    }
  }

  void _showHint() {
    setState(() {
      _progress.hintLevel = (_progress.hintLevel + 1).clamp(1, 3);
      _message = null;
      _panel = _Panel.hint;
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          child: Image.asset(
            _past
                ? 'assets/images/room_1926.png'
                : 'assets/images/room_2126.png',
            key: ValueKey(_progress.era),
            fit: BoxFit.fill,
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
        _hotspot(
          key: const Key('clock-hotspot'),
          label: '大時計',
          left: 30,
          top: 80,
          width: 145,
          height: 480,
          onTap: () => setState(() {
            _message = _past
                ? '組み立て途中の大きな時計。中の歯車が陽を受けて光っている。'
                : '埃をかぶった大時計は、11時58分を指したまま止まっている。';
          }),
        ),
        _hotspot(
          key: const Key('calendar-hotspot'),
          label: _past ? 'カレンダー' : 'カレンダーの跡',
          left: 963,
          top: 110,
          width: 110,
          height: 175,
          onTap: _calendar,
          glint: _past && !_progress.calendarSeen,
        ),
        _hotspot(
          key: const Key('drawer-hotspot'),
          label: '引き出し',
          left: 907,
          top: 395,
          width: 120,
          height: 85,
          onTap: _drawer,
          glint: !_past && !_progress.drawerOpened,
        ),
        _hotspot(
          key: const Key('door-hotspot'),
          label: '扉',
          left: 1165,
          top: 125,
          width: 110,
          height: 430,
          onTap: () => setState(() {
            _message = _past
                ? 'ミオ「お父様が鍵を持って出かけちゃったの。……だから今日は、あなたとふたりきり！」'
                : '鍵穴がない。止まった大時計と、何かで繋がっているようだ。';
          }),
        ),
        if (_past) ...[
          Positioned(
            left: 1010,
            top: 205,
            width: 178,
            height: 500,
            child: Image.asset('assets/images/mio_14.png', fit: BoxFit.contain),
          ),
          _hotspot(
            key: const Key('mio-hotspot'),
            label: 'ミオ',
            left: 1065,
            top: 220,
            width: 114,
            height: 440,
            onTap: () => setState(() {
              _message = 'ミオ「今日はわたしの誕生日なの。壁に印をつけてあるんだよ！」';
            }),
          ),
        ],
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
          top: 22,
          right: 25,
          child: Row(
            children: [
              _TopButton(
                label: '手帳',
                icon: Icons.menu_book_outlined,
                onTap: () => setState(() {
                  _panel = _Panel.notebook;
                  _message = null;
                }),
              ),
              const SizedBox(width: 10),
              _TopButton(
                label: 'ヒント',
                icon: Icons.lightbulb_outline,
                onTap: _showHint,
              ),
              const SizedBox(width: 10),
              _TopButton(
                label: 'タイトル',
                icon: Icons.menu,
                onTap: widget.onTitle,
              ),
            ],
          ),
        ),
        Positioned(left: 26, bottom: 22, child: _itemSlots()),
        Positioned(
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
                    const Icon(
                      Icons.watch_later_outlined,
                      color: _gold,
                      size: 47,
                    ),
                    Text(
                      _past ? '2126へ' : '1926へ',
                      style: const TextStyle(color: _paper, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_message != null)
          Positioned(
            left: 375,
            right: 165,
            bottom: 21,
            child: GestureDetector(
              onTap: () => setState(() => _message = null),
              child: Container(
                constraints: const BoxConstraints(minHeight: 112),
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 17),
                decoration: _glassDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _message!,
                      style: const TextStyle(
                        color: _paper,
                        fontSize: 21,
                        height: 1.5,
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'タップして閉じる  ▸',
                        style: TextStyle(color: _gold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_panel != null) _modal(),
      ],
    );
  }

  Widget _itemSlots() {
    return Row(
      children: List.generate(4, (index) {
        final hasKey = index == 0 && _progress.hasWindKey && !_past;
        return Container(
          width: 72,
          height: 72,
          margin: const EdgeInsets.only(right: 9),
          decoration: _glassDecoration(),
          child: hasKey
              ? const Tooltip(
                  message: '真鍮のねじ巻き鍵',
                  child: Icon(Icons.key, color: _gold, size: 37),
                )
              : null,
        );
      }),
    );
  }

  Widget _hotspot({
    required Key key,
    required String label,
    required double left,
    required double top,
    required double width,
    required double height,
    required VoidCallback onTap,
    bool glint = false,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          key: key,
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: glint
              ? Align(
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withValues(alpha: 0.33),
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

  Widget _modal() {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _panel = null),
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
        return _PaperPanel(
          title: '大正十五年 四月',
          width: 720,
          onClose: () => setState(() => _panel = null),
          child: Column(
            children: [
              const Text(
                'ミオの部屋のカレンダー',
                style: TextStyle(color: _ink, fontSize: 21),
              ),
              const SizedBox(height: 16),
              SizedBox(height: 260, width: 520, child: _calendarGrid()),
              const SizedBox(height: 13),
              const Text(
                '13日に赤い丸。「ミオ 誕生日！」',
                style: TextStyle(
                  color: Color(0xFF8A392F),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case _Panel.drawer:
        return _PaperPanel(
          title: '真鍮のダイヤル錠',
          width: 615,
          onClose: () => setState(() => _panel = null),
          child: Column(
            children: [
              const Text(
                'たいせつな ひ',
                style: TextStyle(color: _ink, fontSize: 28, letterSpacing: 6),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) => _dialColumn(index)),
              ),
              const SizedBox(height: 16),
              if (_wrongCode)
                const Text(
                  '開かない。',
                  style: TextStyle(color: Color(0xFF9B3229), fontSize: 20),
                )
              else
                const SizedBox(height: 30),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('open-drawer'),
                onPressed: _openDrawer,
                icon: const Icon(Icons.lock_open),
                label: const Text('開ける'),
                style: _paperButtonStyle(),
              ),
            ],
          ),
        );
      case _Panel.notebook:
        return _PaperPanel(
          title: '手帳',
          width: 745,
          onClose: () => setState(() => _panel = null),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '見つけた手がかり',
                style: TextStyle(color: _ink, fontSize: 24),
              ),
              const SizedBox(height: 20),
              Text(
                _progress.calendarSeen
                    ? '• 1926年4月のカレンダー。13日に赤丸。ミオの誕生日。'
                    : '• まだ記録はない。百年前の部屋を調べよう。',
                style: const TextStyle(color: _ink, fontSize: 21, height: 1.6),
              ),
              if (_progress.memoRead) ...[
                const SizedBox(height: 24),
                const Text(
                  '文書：未来のお客さまへ',
                  style: TextStyle(color: _ink, fontSize: 24),
                ),
                const SizedBox(height: 12),
                const Text(
                  '大事なものは、百年もつ場所に。\nそれが、時計屋の娘の心得です。',
                  style: TextStyle(color: _ink, fontSize: 21, height: 1.6),
                ),
              ],
            ],
          ),
        );
      case _Panel.hint:
        const hints = [
          '引き出しの錠は3桁で、「たいせつな ひ」。百年前の部屋に、大切な日の印がないかな?',
          '1926年の壁のカレンダーを見てみて。赤い丸がついてるよ。',
          '4月13日で「413」。',
        ];
        return _PaperPanel(
          title: 'ヒント ${_progress.hintLevel} / 3',
          width: 700,
          onClose: () => setState(() => _panel = null),
          child: Column(
            children: [
              Text(
                hints[_progress.hintLevel - 1],
                style: const TextStyle(color: _ink, fontSize: 25, height: 1.7),
              ),
              const SizedBox(height: 28),
              if (_progress.hintLevel < 3)
                FilledButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('次のヒント'),
                  style: _paperButtonStyle(),
                ),
            ],
          ),
        );
      case _Panel.letter:
        return _PaperPanel(
          title: '謎1「カレンダーの丸」クリア',
          width: 755,
          onClose: () => setState(() => _panel = null),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '引き出しの中には、真鍮のねじ巻き鍵と黄ばんだ封筒が入っていた。',
                style: TextStyle(color: _ink, fontSize: 20, height: 1.55),
              ),
              SizedBox(height: 19),
              Text(
                '未来のお客さまへ',
                style: TextStyle(
                  color: Color(0xFF7C4E2E),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'ほんとうに、来てくれたんだね。\nお父様の鍵は、あなたのために、ここへしまっておきます。\n\n大事なものは、百年もつ場所に。\nそれが、時計屋の娘の心得です。\n\n大正十五年 四月十三日 夜  ミオ',
                style: TextStyle(color: _ink, fontSize: 20, height: 1.45),
              ),
              SizedBox(height: 16),
              Text(
                '試作版はここまで。鍵は所持品に入り、手帳から手紙を読み返せます。',
                style: TextStyle(color: Color(0xFF8A392F), fontSize: 17),
              ),
            ],
          ),
        );
    }
  }

  Widget _calendarGrid() {
    final startOffset = DateTime(1926, 4, 1).weekday % 7;
    return Column(
      children: [
        Row(
          children: [
            for (final day in ['日', '月', '火', '水', '木', '金', '土'])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(color: _ink, fontSize: 17),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.55,
            children: List.generate(35, (index) {
              final day = index - startOffset + 1;
              if (day < 1 || day > 30) return const SizedBox();
              return Center(
                child: Container(
                  width: 45,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: day == 13
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFAD3B31),
                            width: 3,
                          ),
                        )
                      : null,
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: day == 13 ? const Color(0xFFAD3B31) : _ink,
                      fontSize: 22,
                      fontWeight: day == 13
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _dialColumn(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          IconButton(
            key: Key('digit-$index-up'),
            onPressed: () => _setDigit(index, 1),
            icon: const Icon(Icons.keyboard_arrow_up, color: _ink, size: 40),
          ),
          Container(
            width: 74,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF46301E),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _gold, width: 3),
            ),
            child: Text(
              _digits[index].toString(),
              style: const TextStyle(
                color: _paper,
                fontSize: 52,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            key: Key('digit-$index-down'),
            onPressed: () => _setDigit(index, -1),
            icon: const Icon(Icons.keyboard_arrow_down, color: _ink, size: 40),
          ),
        ],
      ),
    );
  }
}

class _PaperPanel extends StatelessWidget {
  const _PaperPanel({
    required this.title,
    required this.width,
    required this.onClose,
    required this.child,
  });

  final String title;
  final double width;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(maxHeight: 635),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFAF8752), width: 4),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 16, 17, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: _ink, size: 30),
                ),
              ],
            ),
          ),
          Container(height: 2, color: const Color(0xFFBB9A6B)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 23, 32, 30),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _glassDecoration(),
        child: Row(
          children: [
            Icon(icon, color: _gold, size: 24),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(color: _paper, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

ButtonStyle _paperButtonStyle() => const ButtonStyle(
  backgroundColor: WidgetStatePropertyAll(Color(0xFF7C4E2E)),
  foregroundColor: WidgetStatePropertyAll(_paper),
  padding: WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 26, vertical: 13),
  ),
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 22)),
);

BoxDecoration _glassDecoration() => BoxDecoration(
  color: const Color(0xDF071B27),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: _gold.withValues(alpha: 0.76), width: 1.5),
  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)],
);
