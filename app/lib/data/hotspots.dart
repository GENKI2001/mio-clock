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
    Rect.fromLTWH(38, 450, 118, 100),
    past: false,
  ),
  HotspotDef('pillar', '背比べの柱', Rect.fromLTWH(181, 76, 85, 548)),
  HotspotDef('window', '窓', Rect.fromLTWH(266, 107, 325, 227)),
  // From the jars and clock on its top down to the floor below it.
  HotspotDef('workbench', '作業台', Rect.fromLTWH(228, 300, 398, 262)),
  HotspotDef('blackboard', '黒板', Rect.fromLTWH(650, 107, 172, 176)),
  HotspotDef('fireplace', '暖炉', Rect.fromLTWH(640, 335, 207, 284)),
  HotspotDef('shelfBox', '棚の小箱', Rect.fromLTWH(870, 234, 64, 34)),
  HotspotDef(
    'calendar',
    'カレンダー',
    Rect.fromLTWH(963, 110, 110, 175),
    future: false,
  ),
  HotspotDef(
    'newspaper',
    '古い新聞',
    Rect.fromLTWH(996, 144, 64, 100),
    past: false,
  ),
  HotspotDef('desk', '机', Rect.fromLTWH(884, 325, 213, 236)),
  HotspotDef('drawer', '引き出し', Rect.fromLTWH(903, 390, 86, 48)),
  HotspotDef('chair', '椅子', Rect.fromLTWH(989, 370, 90, 188)),
  HotspotDef('door', '扉', Rect.fromLTWH(1156, 108, 123, 515)),
  HotspotDef('mio', 'ミオ', Rect.fromLTWH(1050, 215, 128, 400), future: false),
];

/// Where the hint glow traces each painted object's edge, which is tighter
/// than the (deliberately generous) tap area.
const glowOutlines = <String, Rect>{
  'calendar': Rect.fromLTWH(974, 128, 74, 156),
  'blackboard': Rect.fromLTWH(652, 112, 166, 131),
  'pillar': Rect.fromLTWH(183, 84, 48, 468),
  'drawer': Rect.fromLTWH(908, 396, 76, 38),
  'chair': Rect.fromLTWH(952, 370, 122, 186),
  'door': Rect.fromLTWH(1158, 108, 120, 452),
  'clock': Rect.fromLTWH(18, 62, 148, 492),
  'shelfBox': Rect.fromLTWH(877, 242, 50, 22),
  'clockBase': Rect.fromLTWH(43, 456, 108, 88),
  'window': Rect.fromLTWH(279, 82, 322, 240),
  'fireplace': Rect.fromLTWH(686, 380, 124, 128),
  'newspaper': Rect.fromLTWH(1004, 150, 49, 86),
};

/// The pocket-watch recess painted into the 2026 door.
/// The lower-left pane of the window that survives to 2026.
const windowCodeRect = Rect.fromLTWH(286, 286, 30, 22);

const doorRecessRect = Rect.fromLTWH(1181, 271, 34, 42);

/// A piece of the room painting repainted for a later state of the story
/// (a pillar before Mio's marks, the clock before its gear…). Each is a
/// transparent PNG covering [rect] in stage coordinates.
class RoomPatch {
  const RoomPatch(this.asset, this.rect);

  final String asset;
  final Rect rect;
}

const _clockPatchRect = Rect.fromLTRB(42.5, 192.1, 153.7, 459.4);
const _pillarPatchRect = Rect.fromLTRB(174.5, 60, 243.2, 562.7);

const clockPatchEmpty = RoomPatch(
  'assets/images/patch_clock_empty.png',
  _clockPatchRect,
);
const clockPatchGear = RoomPatch(
  'assets/images/patch_clock_gear.png',
  _clockPatchRect,
);
const clockPatchFull = RoomPatch(
  'assets/images/patch_clock_full.png',
  _clockPatchRect,
);

const firePatch = RoomPatch(
  'assets/images/patch_fire.png',
  Rect.fromLTRB(673.6, 370, 819.3, 529.4),
);

RoomPatch pillarPatch({required bool past, required bool marked}) => RoomPatch(
  'assets/images/patch_pillar_${past ? 1926 : 2026}_${marked ? 'marked' : 'blank'}.png',
  _pillarPatchRect,
);

const stageRect = Rect.fromLTWH(0, 0, 1280, 720);

/// Where Mio stands in 1926; the box keeps her portrait's 2:3 ratio so the
/// sprite fills it instead of shrinking to the width.
const mioRect = Rect.fromLTWH(975, 215, 267, 400);

class CloseUpZone {
  const CloseUpZone(this.id, this.camera, {this.painted = true});

  final String id;

  /// Whether a detailed close-up painting exists for this camera.
  final bool painted;

  /// The 16:9 part of the stage the camera frames. The close-up paintings
  /// repaint exactly this area, so hotspots and overlays keep their stage
  /// coordinates.
  final Rect camera;

  String asset(bool past) =>
      'assets/images/close_${id}_${past ? 1926 : 2126}.jpg';
}

const closeUpZones = <String, CloseUpZone>{
  'clock': CloseUpZone('clock', Rect.fromLTWH(0, 70, 560, 315)),
  'base': CloseUpZone('base', Rect.fromLTWH(0, 405, 560, 315)),
  'window': CloseUpZone('window', Rect.fromLTWH(230, 70, 640, 360)),
  'workbench': CloseUpZone('workbench', Rect.fromLTWH(230, 300, 640, 360)),
  'bench': CloseUpZone(
    'bench',
    Rect.fromLTWH(300, 330, 300, 169),
    painted: false,
  ),
  'blackboard': CloseUpZone('blackboard', Rect.fromLTWH(560, 60, 560, 315)),
  'fireplace': CloseUpZone('fireplace', Rect.fromLTWH(560, 300, 560, 315)),
  'desk': CloseUpZone('desk', Rect.fromLTWH(720, 230, 560, 315)),
  'door': CloseUpZone('door', Rect.fromLTWH(720, 160, 560, 315)),
};

/// Which close-up each hotspot (or gear resting place) walks up to.
const hotspotZones = <String, String>{
  'clock': 'clock',
  'pillar': 'clock',
  'clockBase': 'base',
  'window': 'window',
  // The bench is looked at from above in its own scene; the camera just
  // leans in over its top first.
  'workbench': 'bench',
  'blackboard': 'blackboard',
  'shelfBox': 'blackboard',
  'calendar': 'blackboard',
  'fireplace': 'fireplace',
  'desk': 'desk',
  'drawer': 'desk',
  'chair': 'desk',
  'newspaper': 'door',
  'door': 'door',
  'mio': 'door',
};

/// The close-up for [id] in the current era. In 1926 Mio stands by the desk,
/// so the camera frames her face rather than the drawer, which only matters
/// in 2026.
CloseUpZone zoneFor(String id, {required bool past}) {
  final zoneId = hotspotZones[id]!;
  return closeUpZones[past && zoneId == 'desk' ? 'door' : zoneId]!;
}
