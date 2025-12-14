import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;
  bool _isInitialized = false;

  // Test Ad Unit IDs
  final String _rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-5674648316804152/8406303668'
      : 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _createRewardedAd();
    } catch (e) {
      debugPrint('Error initializing AdMob: $e');
      _isInitialized = false;
    }
  }

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
            _createRewardedAd();
          }
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required Function onUserEarnedReward,
    Function? onAdDismissed,
    Function? onAdFailedToLoad,
  }) async {
    // Ensure AdMob is initialized before showing ad
    await _ensureInitialized();
    
    if (_rewardedAd == null) {
      debugPrint('Warning: rewarded ad not loaded yet.');
      // Notify that ad failed to load - DO NOT proceed without watching
      if (onAdFailedToLoad != null) {
        onAdFailedToLoad();
      }
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd(); // Load the next one
        if (onAdDismissed != null) onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
        // Ad failed to show - notify error
        if (onAdFailedToLoad != null) {
          onAdFailedToLoad();
        }
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
        onUserEarnedReward();
      },
    );
    _rewardedAd = null;
  }
}
