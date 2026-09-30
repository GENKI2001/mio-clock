import 'dart:convert';

enum Era { past, future }

class GameProgress {
  GameProgress({
    this.era = Era.future,
    this.metMio = false,
    this.calendarSeen = false,
    this.drawerOpened = false,
    this.memoRead = false,
    this.hintLevel = 0,
  });

  Era era;
  bool metMio;
  bool calendarSeen;
  bool drawerOpened;
  bool memoRead;
  int hintLevel;

  bool get hasWindKey => drawerOpened;

  bool get hasProgress =>
      metMio || calendarSeen || drawerOpened || memoRead || hintLevel > 0;

  void travel() {
    era = era == Era.future ? Era.past : Era.future;
    if (era == Era.past) metMio = true;
  }

  bool tryOpenDrawer(List<int> digits) {
    if (era != Era.future || drawerOpened || digits.length != 3) return false;
    if (digits[0] != 4 || digits[1] != 1 || digits[2] != 3) return false;
    drawerOpened = true;
    return true;
  }

  String toJson() => jsonEncode({
    'era': era.name,
    'metMio': metMio,
    'calendarSeen': calendarSeen,
    'drawerOpened': drawerOpened,
    'memoRead': memoRead,
    'hintLevel': hintLevel,
  });

  factory GameProgress.fromJson(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic>) return GameProgress();
      return GameProgress(
        era: value['era'] == 'past' ? Era.past : Era.future,
        metMio: value['metMio'] == true,
        calendarSeen: value['calendarSeen'] == true,
        drawerOpened: value['drawerOpened'] == true,
        memoRead: value['memoRead'] == true,
        hintLevel: (value['hintLevel'] is int)
            ? (value['hintLevel'] as int).clamp(0, 3)
            : 0,
      );
    } catch (_) {
      return GameProgress();
    }
  }
}
