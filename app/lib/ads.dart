import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Rewarded ads that unlock hints.
///
/// Google's public test unit is used unless a release build passes the real
/// one: `flutter build ipa --dart-define=ADMOB_IOS_REWARDED=ca-app-pub-…/…`
/// (and the AdMob app ID goes in ios/Runner/Info.plist). See docs/RELEASE.md.
class HintAds {
  HintAds._();

  static final HintAds instance = HintAds._();

  static const _iosTestUnit = 'ca-app-pub-3940256099942544/1712485313';
  static const _androidTestUnit = 'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _ready;
  Completer<RewardedAd?>? _loading;
  bool _started = false;

  static const _iosUnit = String.fromEnvironment(
    'ADMOB_IOS_REWARDED',
    defaultValue: _iosTestUnit,
  );
  static const _androidUnit = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED',
    defaultValue: _androidTestUnit,
  );

  String get _unitId => Platform.isIOS ? _iosUnit : _androidUnit;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await MobileAds.instance.initialize();
      unawaited(_load());
    } catch (_) {
      // Without ads the hint button reports that none could be shown.
    }
  }

  /// iOS asks once whether ads may use the device's advertising ID. Either
  /// answer is fine: a refusal only means less personalised ads.
  Future<void> _askToTrack() async {
    if (!Platform.isIOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // The prompt only shows while the app is active.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // Ads still load without tracking.
    }
  }

  /// Fetches the next ad so it is ready when a hint is asked for.
  Future<RewardedAd?> _load() {
    final pending = _loading;
    if (_ready != null) return Future.value(_ready);
    if (pending != null) return pending.future;
    final completer = Completer<RewardedAd?>();
    _loading = completer;
    RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ready = ad;
          _loading = null;
          completer.complete(ad);
        },
        onAdFailedToLoad: (_) {
          _loading = null;
          completer.complete(null);
        },
      ),
    );
    return completer.future;
  }

  /// Shows an ad and resolves true only if the viewer earned the reward.
  Future<bool> watchForHint() async {
    // Asked the first time a hint is wanted, not at launch.
    await _askToTrack();
    await start();
    final ad = await _load().timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
    if (ad == null) return false;
    _ready = null;
    final result = Completer<bool>();
    var rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(rewarded);
        unawaited(_load());
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!result.isCompleted) result.complete(false);
        unawaited(_load());
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => rewarded = true);
    return result.future;
  }
}
