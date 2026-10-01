import 'dart:convert';

enum Era { past, future }

/// Items the player can carry in 2026. In 1926 the player is see-through and
/// cannot hold anything, so Mio does the handling there.
const itemOrder = [
  'windKey',
  'matches',
  'gear',
  'driver',
  'blankLetter',
  'pendulum',
  'oil',
];

const itemNames = <String, String>{
  'windKey': 'ねじ巻き鍵',
  'matches': 'マッチ',
  'gear': '歯車',
  'driver': 'ドライバー',
  'blankLetter': '白紙の手紙',
  'pendulum': '振り子',
  'oil': '時計油',
};

class GameProgress {
  GameProgress({
    this.era = Era.future,
    this.introSeen = false,
    this.metMio = false,
    this.drawerOpened = false,
    this.gearInTin = false,
    this.tinOpened = false,
    this.clockGearInstalled = false,
    this.heightMarked = false,
    this.boxOpened = false,
    this.fireLit = false,
    this.chairSearched = false,
    this.clockPendulumInstalled = false,
    this.oilHidden = false,
    this.oilTaken = false,
    this.clockOiled = false,
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

  /// Mio sealed the spare gear into her treasure tin in 1926.
  bool gearInTin;
  bool tinOpened;
  bool clockGearInstalled;

  /// Mio started marking her height on the pillar each birthday.
  bool heightMarked;

  /// The little box on the shelf beside the blackboard, locked with the
  /// year Mio grew the most.
  bool boxOpened;

  /// The 2026 fireplace, lit with the matches.
  bool fireLit;
  bool chairSearched;
  bool clockPendulumInstalled;

  /// Mio sealed clock oil into the clock base's drawer in 1926.
  bool oilHidden;
  bool oilTaken;
  bool clockOiled;
  bool clockRunning;
  int farewellCount;
  final Set<String> inventory;
  final Set<String> docs;
  final Set<String> notes;
  final Map<String, int> hintLevel;
  final Map<String, bool> flags;

  bool get hasProgress =>
      metMio || drawerOpened || docs.isNotEmpty || clockRunning;

  bool flag(String name) => flags[name] == true;

  void travel() {
    if (era == Era.past) {
      farewellCount++;
      era = Era.future;
    } else {
      era = Era.past;
      metMio = true;
    }
  }

  bool tryOpenDrawer(List<int> digits) {
    if (era != Era.future || drawerOpened || !_matches(digits, [4, 1, 3])) {
      return false;
    }
    drawerOpened = true;
    inventory.addAll(['windKey', 'matches']);
    docs.add('memo1');
    return true;
  }

  bool sealGearInTin() {
    if (era != Era.past || gearInTin) return false;
    gearInTin = true;
    notes.add('n_tin');
    return true;
  }

  /// Softens the wax seal with a match and takes out the gear and letter.
  bool openTin() {
    if (era != Era.future ||
        !gearInTin ||
        tinOpened ||
        !inventory.contains('matches')) {
      return false;
    }
    tinOpened = true;
    inventory.add('gear');
    _spendMatchesIfDone();
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

  bool markHeight() {
    if (era != Era.past || heightMarked) return false;
    heightMarked = true;
    notes.add('n_heightStart');
    return true;
  }

  bool tryOpenBox(List<int> digits) {
    if (era != Era.future || boxOpened || !_matches(digits, [1, 9, 2, 8])) {
      return false;
    }
    boxOpened = true;
    inventory.addAll(['driver', 'blankLetter']);
    return true;
  }

  bool lightFire() {
    if (era != Era.future || fireLit || !inventory.contains('matches')) {
      return false;
    }
    fireLit = true;
    _spendMatchesIfDone();
    return true;
  }

  /// The matches are for the tin's wax and the fireplace; once both are
  /// done the box is empty.
  void _spendMatchesIfDone() {
    if (tinOpened && fireLit) inventory.remove('matches');
  }

  /// Warms Mio's citrus-ink letter over the fire until the words show.
  bool revealLetter() {
    if (era != Era.future || !fireLit || !inventory.remove('blankLetter')) {
      return false;
    }
    docs.add('memo3');
    return true;
  }

  /// Unscrews the floorboard under the chair Mio loves.
  bool searchChair() {
    if (era != Era.future ||
        chairSearched ||
        !docs.contains('memo3') ||
        !inventory.contains('driver')) {
      return false;
    }
    chairSearched = true;
    inventory
      ..remove('driver')
      ..add('pendulum');
    docs.add('memo4');
    return true;
  }

  bool installPendulum() {
    if (era != Era.future ||
        !clockGearInstalled ||
        clockPendulumInstalled ||
        !inventory.remove('pendulum')) {
      return false;
    }
    clockPendulumInstalled = true;
    return true;
  }

  bool hideOil() {
    if (era != Era.past || oilHidden || !flag('springRusty')) return false;
    oilHidden = true;
    notes.add('n_oil');
    return true;
  }

  /// The clock base's drawer, locked with the number Mio got from her father
  /// and scratched into the window glass.
  bool tryOpenBase(List<int> digits) {
    if (era != Era.future ||
        !oilHidden ||
        flag('baseUnlocked') ||
        !_matches(digits, [2, 7, 5])) {
      return false;
    }
    flags['baseUnlocked'] = true;
    return true;
  }

  bool takeOil() {
    if (era != Era.future || !oilHidden || oilTaken || !flag('baseUnlocked')) {
      return false;
    }
    oilTaken = true;
    inventory.add('oil');
    return true;
  }

  bool oilClock() {
    if (era != Era.future ||
        clockOiled ||
        !clockPendulumInstalled ||
        !inventory.remove('oil')) {
      return false;
    }
    clockOiled = true;
    return true;
  }

  bool windClock() {
    if (era != Era.future ||
        clockRunning ||
        !clockGearInstalled ||
        !clockPendulumInstalled ||
        !clockOiled ||
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
    if (!boxOpened) return 's3';
    if (!clockPendulumInstalled) return 's4';
    if (!clockRunning) return 's5';
    return 's6';
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
    'gearInTin': gearInTin,
    'tinOpened': tinOpened,
    'clockGearInstalled': clockGearInstalled,
    'heightMarked': heightMarked,
    'boxOpened': boxOpened,
    'fireLit': fireLit,
    'chairSearched': chairSearched,
    'clockPendulumInstalled': clockPendulumInstalled,
    'oilHidden': oilHidden,
    'oilTaken': oilTaken,
    'clockOiled': clockOiled,
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
      bool read(String key) => decoded[key] == true;
      final hints = <String, int>{};
      if (decoded['hintLevel'] is Map) {
        for (final entry in (decoded['hintLevel'] as Map).entries) {
          if (entry.key is String && entry.value is int) {
            hints[entry.key as String] = (entry.value as int).clamp(0, 3);
          }
        }
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
        introSeen: read('introSeen'),
        metMio: read('metMio'),
        drawerOpened: read('drawerOpened'),
        gearInTin: read('gearInTin'),
        tinOpened: read('tinOpened'),
        clockGearInstalled: read('clockGearInstalled'),
        heightMarked: read('heightMarked'),
        boxOpened: read('boxOpened'),
        fireLit: read('fireLit'),
        chairSearched: read('chairSearched'),
        clockPendulumInstalled: read('clockPendulumInstalled'),
        oilHidden: read('oilHidden'),
        oilTaken: read('oilTaken'),
        clockOiled: read('clockOiled'),
        clockRunning: read('clockRunning'),
        farewellCount: decoded['farewellCount'] is int
            ? decoded['farewellCount'] as int
            : 0,
        inventory: _stringSet(decoded['inventory']),
        docs: _stringSet(decoded['docs']),
        notes: _stringSet(decoded['notes']),
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
    gearInTin: true,
    tinOpened: true,
    clockGearInstalled: true,
    heightMarked: true,
    boxOpened: true,
    fireLit: true,
    chairSearched: true,
    clockPendulumInstalled: true,
    oilHidden: true,
    oilTaken: true,
    clockOiled: true,
    clockRunning: true,
    docs: {'memo1', 'memo2', 'memo3', 'memo4', 'newspaper'},
    flags: {
      'doorRecessSeen': true,
      'tourStarted': true,
      'clockChecked': true,
      'tourDone': true,
      'watchPromised': true,
      'springRusty': true,
      'favoritePlace': true,
      'codeOnBoard': true,
      'codeOnWindow': true,
      'baseUnlocked': true,
    },
    notes: {
      'n_watchMT',
      'n_calendar',
      'n_missingGear',
      'n_tin',
      'n_heightStart',
      'n_pillar',
      'n_boxLock',
      'n_favoritePlace',
      'n_rustySpring',
      'n_oil',
      'n_clockRunning',
      'n_door',
      'n_clockStopped',
      'n_watchPromise',
      'n_mioWatch',
    },
  );
}
