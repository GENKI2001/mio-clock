import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Full-screen close-ups the room cuts to when the player leans in: a
/// painted view with the interactive bits laid over it in stage coordinates.
const _gold = Color(0xFFE8BF79);
const _ink = Color(0xFF34291F);
const _red = Color(0xFF9B3F31);

class _ScenePainting extends StatelessWidget {
  const _ScenePainting(this.asset, {super.key, required this.fallback});

  final String asset;
  final Color fallback;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.medium,
    errorBuilder: (_, error, stack) => ColoredBox(color: fallback),
  );
}

/// A sprite laid on a painting, with a faint gold rim that follows its own
/// outline while it still matters.
class SceneSprite extends StatelessWidget {
  const SceneSprite(
    this.asset, {
    super.key,
    this.highlighted = false,
    this.fallback = Icons.help_outline,
  });

  final String asset;
  final bool highlighted;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    Widget image({Color? tint}) => Image.asset(
      asset,
      fit: BoxFit.contain,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcIn,
      errorBuilder: (_, error, stack) => Icon(fallback, color: _gold, size: 40),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (highlighted)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: image(tint: _gold.withValues(alpha: 0.8)),
          ),
        image(),
      ],
    );
  }
}

Widget _tapTarget({
  required Key key,
  required Rect rect,
  required String label,
  required VoidCallback onTap,
  required Widget child,
}) {
  return Positioned.fromRect(
    rect: rect,
    child: Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    ),
  );
}

enum TinLook {
  none,
  closed1926,
  open1926,
  gear1926,
  sealed2026,
  gear2026,
  open2026,
}

/// Looking straight down at the workbench, where the spare gear and Mio's
/// treasure tin sit side by side.
class WorkbenchScene extends StatelessWidget {
  const WorkbenchScene({
    super.key,
    required this.past,
    required this.showGear,
    required this.tin,
    required this.gearHighlighted,
    required this.tinHighlighted,
    required this.onGear,
    required this.onTin,
  });

  static const gearRect = Rect.fromLTWH(430, 300, 170, 170);
  static const tinRect = Rect.fromLTWH(660, 250, 280, 250);

  final bool past;
  final bool showGear;
  final TinLook tin;
  final bool gearHighlighted;
  final bool tinHighlighted;
  final VoidCallback onGear;
  final VoidCallback onTin;

  @override
  Widget build(BuildContext context) {
    final tinAsset = switch (tin) {
      TinLook.closed1926 => 'assets/images/item_tin_top_1926.png',
      TinLook.open1926 => 'assets/images/item_tin_top_1926_open.png',
      TinLook.gear1926 => 'assets/images/item_tin_top_1926_gear.png',
      TinLook.gear2026 => 'assets/images/item_tin_top_2026_gear.png',
      TinLook.sealed2026 => 'assets/images/item_tin_top_2026.png',
      TinLook.open2026 => 'assets/images/item_tin_top_2026_open.png',
      TinLook.none => null,
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        _ScenePainting(
          past
              ? 'assets/images/scene_workbench_1926.jpg'
              : 'assets/images/scene_workbench_2026.jpg',
          fallback: past ? const Color(0xFF6B4A2B) : const Color(0xFF1A2230),
        ),
        if (showGear)
          _tapTarget(
            key: const Key('scene-gear'),
            rect: gearRect,
            label: '予備の歯車',
            onTap: onGear,
            child: SceneSprite(
              'assets/images/item_gear.png',
              highlighted: gearHighlighted,
              fallback: Icons.settings,
            ),
          ),
        if (tinAsset != null)
          _tapTarget(
            key: const Key('scene-tin'),
            rect: tinRect,
            label: 'ミオの宝物缶',
            onTap: onTin,
            // A short cross-fade between still frames of the tin.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: SceneSprite(
                tinAsset,
                key: ValueKey(tinAsset),
                highlighted: tinHighlighted,
                fallback: Icons.inventory_2_outlined,
              ),
            ),
          ),
      ],
    );
  }
}

/// The brass three-wheel lock on the desk drawer.
/// Where a painted combination lock's plate and wheel windows sit.
class LockLayout {
  const LockLayout({
    required this.asset,
    required this.inscription,
    required this.plateRect,
    required this.wheelCentres,
    this.inscriptionSize = 25,
    this.digitSize = 40,
    this.wheelHalfHeight = 76,
  });

  final String asset;
  final String inscription;
  final Rect plateRect;
  final List<Offset> wheelCentres;
  final double inscriptionSize;

  /// Font size of the numbers in the wheel windows.
  final double digitSize;

  /// Half the painted wheel's height; the arrows sit just beyond it.
  final double wheelHalfHeight;

  /// Arrows stay inside a wheel's own column, however close the wheels sit.
  double get arrowWidth => wheelCentres.length < 2
      ? 72
      : ((wheelCentres[1].dx - wheelCentres[0].dx) - 4).clamp(24.0, 72.0);
}

/// The three-wheel lock on the desk drawer.
const drawerLock = LockLayout(
  asset: 'assets/images/scene_lock.jpg',
  inscription: 'たいせつな ひ',
  plateRect: Rect.fromLTWH(530, 232, 235, 44),
  wheelCentres: [Offset(577, 398), Offset(649, 398), Offset(721, 398)],
);

/// The three-wheel lock Mio put on the clock base's little drawer.
const baseLock = LockLayout(
  asset: 'assets/images/scene_base_locked.jpg',
  inscription: '',
  plateRect: Rect.zero,
  wheelCentres: [Offset(591, 342), Offset(631, 342), Offset(672, 342)],
  digitSize: 24,
  wheelHalfHeight: 40,
);

/// The four-wheel lock on the little box beside the blackboard.
const boxLock = LockLayout(
  asset: 'assets/images/scene_boxlock.jpg',
  inscription: '背の のびた年',
  inscriptionSize: 21,
  plateRect: Rect.fromLTWH(548, 216, 188, 40),
  wheelCentres: [
    Offset(553, 375),
    Offset(617, 375),
    Offset(681, 375),
    Offset(743, 375),
  ],
);

/// A brass combination lock seen up close, its wheels turned by tapping the
/// arrows above and below each window.
class LockScene extends StatelessWidget {
  const LockScene({
    super.key,
    required this.layout,
    required this.digits,
    required this.onDigit,
  });

  final LockLayout layout;
  final List<int> digits;
  final void Function(int index, int delta) onDigit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ScenePainting(layout.asset, fallback: const Color(0xFF2A2119)),
        Positioned.fromRect(
          rect: layout.plateRect,
          child: Center(
            child: Text(
              layout.inscription,
              textAlign: TextAlign.center,
              // Cut into the brass: a dark groove with a pale lower lip.
              style: TextStyle(
                color: const Color(0xFF140C05),
                fontSize: layout.inscriptionSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
                shadows: const [
                  Shadow(color: Color(0xCCF6DFA4), offset: Offset(0, 1.5)),
                ],
              ),
            ),
          ),
        ),
        for (var index = 0; index < digits.length; index++) ...[
          Positioned(
            left: layout.wheelCentres[index].dx - layout.arrowWidth / 2,
            top: layout.wheelCentres[index].dy - layout.wheelHalfHeight - 42,
            width: layout.arrowWidth,
            height: 40,
            child: _arrow(
              Key('lock-up-$index'),
              Icons.keyboard_arrow_up,
              () => onDigit(index, 1),
            ),
          ),
          Positioned(
            left: layout.wheelCentres[index].dx - 22,
            top: layout.wheelCentres[index].dy - 31,
            width: 44,
            height: 62,
            child: Center(
              child: Text(
                '${digits[index]}',
                style: TextStyle(
                  color: const Color(0xFFE9D9B4),
                  fontSize: layout.digitSize,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ),
          Positioned(
            left: layout.wheelCentres[index].dx - layout.arrowWidth / 2,
            top: layout.wheelCentres[index].dy + layout.wheelHalfHeight,
            width: layout.arrowWidth,
            height: 44,
            child: _arrow(
              Key('lock-down-$index'),
              Icons.keyboard_arrow_down,
              () => onDigit(index, -1),
            ),
          ),
        ],
      ],
    );
  }

  Widget _arrow(Key key, IconData icon, VoidCallback onTap) => GestureDetector(
    key: key,
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Icon(icon, color: const Color(0xDDF3E6C8), size: 44),
  );
}

/// Mio's hanging calendar for April 1926.
class CalendarScene extends StatelessWidget {
  const CalendarScene({super.key});

  /// The blank ruled area of the painted calendar where the dates go.
  /// The painted 7×6 ruled grid, and the pale sky of the ink painting above
  /// it where the month is printed.
  static const gridRect = Rect.fromLTWH(495, 372, 278, 223);
  static const headerRect = Rect.fromLTWH(495, 128, 278, 30);

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(1926, 4, 1).weekday % 7;
    const inkStyle = TextStyle(color: _ink, fontSize: 17, height: 1);
    return Stack(
      fit: StackFit.expand,
      children: [
        const _ScenePainting(
          'assets/images/scene_calendar.jpg',
          fallback: Color(0xFFD8C39B),
        ),
        Positioned.fromRect(
          rect: headerRect,
          child: const Center(
            child: Text(
              '大正十五年　四月',
              style: TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: gridRect,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (final (index, day) in [
                      '日',
                      '月',
                      '火',
                      '水',
                      '木',
                      '金',
                      '土',
                    ].indexed)
                      Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: inkStyle.copyWith(
                              fontSize: 14,
                              color: index == 0 ? _red : _ink,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var week = 0; week < 5; week++)
                Expanded(
                  child: Row(
                    children: [
                      for (var weekday = 0; weekday < 7; weekday++)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final day = week * 7 + weekday - firstDay + 1;
                              if (day < 1 || day > 30) return const SizedBox();
                              final birthday = day == 13;
                              return Center(
                                child: Container(
                                  width: 31,
                                  height: 31,
                                  alignment: Alignment.center,
                                  decoration: birthday
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _red,
                                            width: 2.5,
                                          ),
                                        )
                                      : null,
                                  child: Text(
                                    '$day',
                                    style: inkStyle.copyWith(
                                      color: birthday || weekday == 0
                                          ? _red
                                          : _ink,
                                      fontWeight: birthday
                                          ? FontWeight.w700
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Mio's red pencil, squeezed into the empty days before the 1st.
        Positioned(
          left: gridRect.left + 4,
          top: gridRect.top + gridRect.height / 6 + 6,
          width: gridRect.width * 4 / 7 - 8,
          child: Transform.rotate(
            angle: -0.04,
            child: const Text(
              '13日は ミオの誕生日!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _red,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The yellowed 1930 paper about the finished clock, read up close.
class NewspaperScene extends StatelessWidget {
  const NewspaperScene({super.key, required this.headline, required this.body});

  static const paperRect = Rect.fromLTWH(150, 60, 980, 580);

  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _ScenePainting(
          'assets/images/scene_newspaper.jpg',
          fallback: Color(0xFF1B1A18),
        ),
        Positioned.fromRect(
          rect: paperRect,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 14, 40, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '東都日日新聞',
                  style: TextStyle(
                    color: Color(0xE62A2016),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                const Text(
                  '昭和五年四月十四日',
                  style: TextStyle(color: Color(0xCC2A2016), fontSize: 17),
                ),
                const SizedBox(height: 18),
                Text(
                  headline,
                  style: const TextStyle(
                    color: Color(0xEE1F1710),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xD92A2016),
                      fontSize: 20,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HeightMark {
  const HeightMark(this.year, this.centimetres);

  final int year;
  final int centimetres;

  String get label => '$year  $centimetres';
}

/// The height pillar up close, with whatever marks Mio has carved so far.
class PillarScene extends StatelessWidget {
  const PillarScene({super.key, required this.past, required this.marks});

  /// The pillar's painted face, and where 142 cm and 154 cm land on it.
  /// The painted pillar's face differs a little between the two paintings.
  static const pillar1926 = (left: 512.0, width: 246.0);
  static const pillar2026 = (left: 482.0, width: 232.0);
  static const topCm = 154;
  static const topY = 200.0;
  static const pixelsPerCm = 26.0;

  final bool past;
  final List<HeightMark> marks;

  @override
  Widget build(BuildContext context) {
    final (:left, :width) = past ? pillar1926 : pillar2026;
    return Stack(
      fit: StackFit.expand,
      children: [
        _ScenePainting(
          past
              ? 'assets/images/scene_pillar_1926.jpg'
              : 'assets/images/scene_pillar_2026.jpg',
          fallback: past ? const Color(0xFF6B4A2B) : const Color(0xFF1A2230),
        ),
        for (final mark in marks) ...[
          Positioned(
            left: left + 14,
            top: _y(mark) - 3,
            width: width * 0.42,
            height: 6,
            child: const CustomPaint(painter: _NotchPainter()),
          ),
          // Mio cut the year and her height into the wood with the same
          // knife: a dark groove with a pale lower edge.
          Positioned(
            left: left + width * 0.42 + 24,
            top: _y(mark) - 12,
            child: Text(
              mark.label,
              style: TextStyle(
                fontFamily: 'MioHand',
                color: past ? const Color(0xE8241509) : const Color(0xF0080503),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                shadows: [
                  Shadow(
                    color: past
                        ? const Color(0xAAF7DDB0)
                        : const Color(0xCCC9D4E6),
                    offset: const Offset(0, 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  double _y(HeightMark mark) => topY + (topCm - mark.centimetres) * pixelsPerCm;
}

/// A knife notch cut into wood: a dark groove with a pale lower lip.
class _NotchPainter extends CustomPainter {
  const _NotchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final groove = Paint()
      ..color = const Color(0xCC1E130B)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final lip = Paint()
      ..color = const Color(0x88F2D9AE)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), groove);
    canvas.drawLine(Offset(1, y + 2), Offset(size.width - 1, y + 2), lip);
  }

  @override
  bool shouldRepaint(_NotchPainter oldDelegate) => false;
}

/// The door up close: a recess cut to the shape of Mio's pocket watch, and
/// the same door once the watch has gone into it.
class DoorScene extends StatelessWidget {
  const DoorScene({super.key, required this.glowing, required this.watchIn});

  final bool glowing;
  final bool watchIn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          child: _ScenePainting(
            watchIn
                ? 'assets/images/scene_door_watch.jpg'
                : 'assets/images/scene_door.jpg',
            key: ValueKey(watchIn),
            fallback: const Color(0xFF1A1714),
          ),
        ),
      ],
    );
  }
}

/// The clock base's drawer pulled open, with Mio's bottle of oil inside
/// until the player takes it.
class BaseDrawerScene extends StatelessWidget {
  const BaseDrawerScene({
    super.key,
    required this.showOil,
    required this.onOil,
  });

  static const oilRect = Rect.fromLTWH(588, 176, 96, 148);

  final bool showOil;
  final VoidCallback onOil;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _ScenePainting(
          'assets/images/scene_base_open.jpg',
          fallback: Color(0xFF1A1714),
        ),
        if (showOil)
          _tapTarget(
            key: const Key('scene-oil'),
            rect: oilRect,
            label: '時計油の小瓶',
            onTap: onOil,
            child: const SceneSprite(
              'assets/images/item_oil.png',
              highlighted: true,
              fallback: Icons.water_drop_outlined,
            ),
          ),
      ],
    );
  }
}
