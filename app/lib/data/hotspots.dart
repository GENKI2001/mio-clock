import 'package:flutter/material.dart';

class HotspotDef {
  const HotspotDef(
    this.id,
    this.label,
    this.bounds, {
    this.past = true,
    this.future = true,
  });

  final String id;
  final String label;
  final Rect bounds;
  final bool past;
  final bool future;
}

// The background paintings use a fixed 1280×720 canvas. Their interactive
// rectangles follow the visible objects in those paintings.
const roomHotspots = <HotspotDef>[
  HotspotDef('clock', '大時計', Rect.fromLTWH(25, 79, 155, 480)),
  HotspotDef(
    'clockBase',
    '大時計の台座',
    Rect.fromLTWH(35, 539, 142, 95),
    past: false,
  ),
  HotspotDef('pillar', '背比べの柱', Rect.fromLTWH(181, 76, 85, 548)),
  HotspotDef('window', '窓', Rect.fromLTWH(266, 107, 325, 227)),
  HotspotDef('windowsill', '窓辺', Rect.fromLTWH(285, 340, 300, 62)),
  HotspotDef('workbench', '作業台', Rect.fromLTWH(296, 412, 326, 202)),
  HotspotDef('tin', 'ミオの宝物缶', Rect.fromLTWH(520, 325, 100, 85), future: false),
  HotspotDef('blackboard', '黒板', Rect.fromLTWH(650, 107, 172, 176)),
  HotspotDef('fireplace', '暖炉', Rect.fromLTWH(640, 335, 207, 284)),
  HotspotDef('niche', '隠し棚', Rect.fromLTWH(800, 310, 90, 105), past: false),
  HotspotDef('calendar', 'カレンダー', Rect.fromLTWH(963, 110, 110, 175)),
  HotspotDef(
    'newspaper',
    '古い新聞',
    Rect.fromLTWH(1070, 179, 80, 89),
    past: false,
  ),
  HotspotDef('desk', '机', Rect.fromLTWH(884, 325, 213, 236)),
  HotspotDef('drawer', '引き出し', Rect.fromLTWH(907, 396, 120, 84)),
  HotspotDef('chair', '椅子', Rect.fromLTWH(1045, 375, 103, 233), past: false),
  HotspotDef('door', '扉', Rect.fromLTWH(1156, 108, 123, 515)),
  HotspotDef('mio', 'ミオ', Rect.fromLTWH(1050, 205, 136, 442), future: false),
];

const gearPositions = <String, Offset>{
  'workbench': Offset(482, 367),
  'windowsill': Offset(475, 337),
  'desk': Offset(979, 326),
  'fireplace': Offset(710, 446),
};
