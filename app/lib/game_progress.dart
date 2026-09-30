import 'dart:convert';

enum Era { past, future }

enum GearSpot { workbench, windowsill, desk, fireplace, tin }

class GameProgress {
  GameProgress({
    this.era = Era.future,
    this.introSeen = false,
    this.metMio = false,
    this.drawerOpened = false,
    this.gearSpot = GearSpot.workbench,
    this.holding1926 = false,
    this.nicheRevealed = false,
    this.tinOpened2126 = false,
    this.heightMarked = false,
    this.backPanelOpened = false,
    this.cipherLearned = false,
    this.chairSearched = false,
    this.clockGearInstalled = false,
    this.clockPendulumInstalled = false,
    this.clockRunning = false,
    this.farewellCount = 0,
    Set<String>? inventory,
    Set<String>? docs,
    Set<String>? notes,
    Map<String, int>? hintLevel,
    Map<String, bool>? flags,
  }) : inventory = inventory ?? <String>{},
       docs = docs ?? <String>{},
       notes = notes ?? <String>{},
       hintLevel = hintLevel ?? <String, int>{},
       flags = flags ?? <String, bool>{};

  Era era;
  bool introSeen;
  bool metMio;
  bool drawerOpened;
  GearSpot gearSpot;
  bool holding1926;
  bool nicheRevealed;
  bool tinOpened2126;
  bool heightMarked;
  bool backPanelOpened;
  bool cipherLearned;
  bool chairSearched;
  bool clockGearInstalled;
  bool clockPendulumInstalled;
  bool clockRunning;
  int farewellCount;
  final Set<String> inventory;
  final Set<String> docs;
  final Set<String> notes;
  final Map<String, int> hintLevel;
  final Map<String, bool> flags;

  bool get hasProgress =>
      metMio ||
      drawerOpened ||
      notes.isNotEmpty ||
      docs.isNotEmpty ||
      gearSpot != GearSpot.workbench ||
      clockRunning;

  bool get hasWindKey => inventory.contains('windKey');
  bool get hasGear => inventory.contains('gear');
  bool get hasPendulum => inventory.contains('pendulum');

  void travel() {
    if (era == Era.past) {
      holding1926 = false;
      farewellCount++;
      era = Era.future;
    } else {
      era = Era.past;
      if (!metMio) {
        metMio = true;
        notes.add('n_promise');
      }
    }
  }

  bool tryOpenDrawer(List<int> digits) {
    if (era != Era.future || drawerOpened || !_matches(digits, [4, 1, 3])) {
      return false;
    }
    drawerOpened = true;
    inventory.add('windKey');
    docs.add('memo1');
    return true;
  }

  bool pickGear() {
    if (era != Era.past || holding1926 || gearSpot == GearSpot.tin) {
      return false;
    }
    holding1926 = true;
    flags['gearHeld'] = true;
    return true;
  }

  bool placeGear(GearSpot spot) {
    if (era != Era.past || !holding1926 || gearSpot == GearSpot.tin) {
      return false;
    }
    gearSpot = spot;
    holding1926 = false;
    if (spot == GearSpot.tin) {
      nicheRevealed = true;
      notes.add('n_niche');
    }
    return true;
  }

  bool collectGear() {
    if (era != Era.future ||
        gearSpot != GearSpot.tin ||
        !nicheRevealed ||
        tinOpened2126) {
      return false;
    }
    tinOpened2126 = true;
    inventory.add('gear');
    docs.add('memo2');
    return true;
  }

  bool installGear() {
    if (era != Era.future || clockGearInstalled || !inventory.remove('gear')) {
      return false;
    }
    clockGearInstalled = true;
    return true;
  }

  bool tryOpenBackPanel(List<int> digits) {
    if (era != Era.future ||
        !clockGearInstalled ||
        backPanelOpened ||
        !_matches(digits, [1, 9, 2, 8])) {
      return false;
    }
    backPanelOpened = true;
    docs.add('memo3');
    return true;
  }

  bool searchChair() {
    if (era != Era.future ||
        chairSearched ||
        !docs.contains('memo3') ||
        !cipherLearned) {
      return false;
    }
    chairSearched = true;
    inventory.add('pendulum');
    docs.add('memo4');
    return true;
  }

  bool installPendulum() {
    if (era != Era.future ||
        !backPanelOpened ||
        clockPendulumInstalled ||
        !inventory.remove('pendulum')) {
      return false;
    }
    clockPendulumInstalled = true;
    return true;
  }

  bool windClock() {
    if (era != Era.future ||
        clockRunning ||
        !clockGearInstalled ||
        !clockPendulumInstalled ||
        !inventory.remove('windKey')) {
      return false;
    }
    clockRunning = true;
    notes.add('n_clockRunning');
    return true;
  }

  String currentStage(Set<String> endings) {
    if (!drawerOpened) return 's1';
    if (!clockGearInstalled) return 's2';
    if (!backPanelOpened) return 's3';
    if (!clockPendulumInstalled) return 's4';
    if (!clockRunning) return 's5';
    return endings.contains('normal') ? 'sTrue' : 's6';
  }

  int revealHint(String stage) {
    final next = ((hintLevel[stage] ?? 0) + 1).clamp(1, 3);
    hintLevel[stage] = next;
    return next;
  }

  static bool _matches(List<int> actual, List<int> expected) {
    if (actual.length != expected.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (actual[index] != expected[index]) return false;
    }
    return true;
  }

  String toJson() => jsonEncode({
    'era': era.name,
    'introSeen': introSeen,
    'metMio': metMio,
    'drawerOpened': drawerOpened,
    'gearSpot': gearSpot.name,
    'holding1926': holding1926,
    'nicheRevealed': nicheRevealed,
    'tinOpened2126': tinOpened2126,
    'heightMarked': heightMarked,
    'backPanelOpened': backPanelOpened,
    'cipherLearned': cipherLearned,
    'chairSearched': chairSearched,
    'clockGearInstalled': clockGearInstalled,
    'clockPendulumInstalled': clockPendulumInstalled,
    'clockRunning': clockRunning,
    'farewellCount': farewellCount,
    'inventory': inventory.toList(),
    'docs': docs.toList(),
    'notes': notes.toList(),
    'hintLevel': hintLevel,
    'flags': flags,
  });

  factory GameProgress.fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return GameProgress();
      final spotName = decoded['gearSpot'];
      final spot = GearSpot.values.firstWhere(
        (value) => value.name == spotName,
        orElse: () => GearSpot.workbench,
      );
      final inventory = _stringSet(decoded['inventory']);
      if (decoded['inventory'] == null && decoded['drawerOpened'] == true) {
        inventory.add('windKey');
      }
      final docs = _stringSet(decoded['docs']);
      if (decoded['memoRead'] == true) docs.add('memo1');
      final notes = _stringSet(decoded['notes']);
      if (decoded['calendarSeen'] == true) notes.add('n_calendar');
      final hints = <String, int>{};
      if (decoded['hintLevel'] is Map) {
        for (final entry in (decoded['hintLevel'] as Map).entries) {
          if (entry.key is String && entry.value is int) {
            hints[entry.key as String] = (entry.value as int).clamp(0, 3);
          }
        }
      } else if (decoded['hintLevel'] is int) {
        hints['s1'] = (decoded['hintLevel'] as int).clamp(0, 3);
      }
      final flags = <String, bool>{};
      if (decoded['flags'] is Map) {
        for (final entry in (decoded['flags'] as Map).entries) {
          if (entry.key is String && entry.value is bool) {
            flags[entry.key as String] = entry.value as bool;
          }
        }
      }
      return GameProgress(
        era: decoded['era'] == 'past' ? Era.past : Era.future,
        introSeen:
            decoded['introSeen'] == true ||
            decoded['metMio'] == true ||
            decoded['drawerOpened'] == true,
        metMio: decoded['metMio'] == true,
        drawerOpened: decoded['drawerOpened'] == true,
        gearSpot: spot,
        holding1926: decoded['holding1926'] == true,
        nicheRevealed: decoded['nicheRevealed'] == true,
        tinOpened2126: decoded['tinOpened2126'] == true,
        heightMarked: decoded['heightMarked'] == true,
        backPanelOpened: decoded['backPanelOpened'] == true,
        cipherLearned: decoded['cipherLearned'] == true,
        chairSearched: decoded['chairSearched'] == true,
        clockGearInstalled: decoded['clockGearInstalled'] == true,
        clockPendulumInstalled: decoded['clockPendulumInstalled'] == true,
        clockRunning: decoded['clockRunning'] == true,
        farewellCount: decoded['farewellCount'] is int
            ? decoded['farewellCount'] as int
            : 0,
        inventory: inventory,
        docs: docs,
        notes: notes,
        hintLevel: hints,
        flags: flags,
      );
    } catch (_) {
      return GameProgress();
    }
  }

  static Set<String> _stringSet(dynamic value) =>
      value is List ? value.whereType<String>().toSet() : <String>{};

  factory GameProgress.readyAtDoor() => GameProgress(
    era: Era.future,
    introSeen: true,
    metMio: true,
    drawerOpened: true,
    gearSpot: GearSpot.tin,
    nicheRevealed: true,
    tinOpened2126: true,
    heightMarked: true,
    backPanelOpened: true,
    cipherLearned: true,
    chairSearched: true,
    clockGearInstalled: true,
    clockPendulumInstalled: true,
    clockRunning: true,
    docs: {'memo1', 'memo2', 'memo3', 'memo4', 'newspaper'},
    notes: {
      'n_watchMT',
      'n_promise',
      'n_calendar',
      'n_missingGear',
      'n_niche',
      'n_heightStart',
      'n_pillar',
      'n_backPanelLock',
      'n_cipher',
      'n_example',
      'n_clockRunning',
      'n_door',
      'n_mioWatch',
    },
  );
}
