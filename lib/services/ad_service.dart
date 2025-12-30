import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isInitialized = false;

  // Ad Unit IDs
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      // Use Test ID in Debug mode, Real ID in Release mode
      return kDebugMode 
          ? 'ca-app-pub-3940256099942544/5224354917' // Android Test ID
          : 'ca-app-pub-5674648316804152/8406303668'; // Android Real ID
    } else {
      // iOS Test ID (Replace with Real ID when ready)
      return 'ca-app-pub-3940256099942544/1712485313';
    }
  }

  Completer<RewardedAd?>? _adLoadCompleter;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _loadRewardedAd(); // Start loading
    } catch (e) {
      debugPrint('Error initializing AdMob: $e');
      _isInitialized = false;
    }
  }

  Future<RewardedAd?> _loadRewardedAd() async {
    if (_rewardedAd != null) return _rewardedAd;
    
    // If already loading, return existing future
    if (_adLoadCompleter != null && !_adLoadCompleter!.isCompleted) {
      return _adLoadCompleter!.future;
    }

    _adLoadCompleter = Completer<RewardedAd?>();
    
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          _adLoadCompleter?.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _adLoadCompleter?.complete(null);
        },
      ),
    );
    
    return _adLoadCompleter!.future;
  }

  Future<void> showRewardedAd({
    required Function onUserEarnedReward,
    Function? onAdDismissed,
    Function? onAdFailedToLoad,
  }) async {
    // Ensure AdMob is initialized
    await _ensureInitialized();
    
    // Try to get existing ad or wait for loading to finish
    RewardedAd? ad = await _loadRewardedAd();
    
    if (ad == null) {
      debugPrint('Warning: rewarded ad failed to load after waiting.');
      if (onAdFailedToLoad != null) {
        onAdFailedToLoad();
      }
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _rewardedAd = null; // Clear current ad
        _loadRewardedAd(); // Pre-load the next one
        if (onAdDismissed != null) onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Try to load again
        if (onAdFailedToLoad != null) {
          onAdFailedToLoad();
        }
      },
    );

    ad.setImmersiveMode(true);
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
        onUserEarnedReward();
      },
    );
  }
}
