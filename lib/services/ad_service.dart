import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/constants.dart';

/// Centralised AdMob wrapper. Ads are mobile-only: on web/desktop all calls
/// no-op and [buildBannerAd] returns null so the UI can skip rendering.
///
/// Premium users never see ads — the caller passes `isPremium` (or checks the
/// provider) and the service short-circuits.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;

  // Interstitial cooldown / rate-limiting to avoid being annoying.
  static const int _maxPerDay = 3;
  static const Duration _minInterval = Duration(minutes: 2);
  DateTime? _lastShown;
  int _shownToday = 0;
  DateTime _dayBucket = _today();

  /// Initialises the Mobile Ads SDK. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    if (!_isMobilePlatform) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('AdService.init failed: $e');
    }
  }

  static bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── Banner ───────────────────────────────────────────────────────────────

  /// Creates a loaded [BannerAd] ready to display, or `null` when ads should
  /// not be shown (non-mobile, premium, or load failure).
  Future<BannerAd?> buildBannerAd() async {
    if (!_isMobilePlatform) return null;
    if (!_initialized) await init();
    final completer = BannerAd(
      adUnitId: AppConstants.admobBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner failed: $err');
          ad.dispose();
        },
      ),
    );
    try {
      await completer.load();
      return completer;
    } catch (e) {
      debugPrint('Banner load failed: $e');
      return null;
    }
  }

  // ── Interstitial ─────────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (!_isMobilePlatform || _interstitialLoading || _interstitial != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AppConstants.admobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (err) {
          _interstitialLoading = false;
          debugPrint('Interstitial load failed: $err');
        },
      ),
    );
  }

  /// Shows an interstitial ad if one is ready and the cooldown/rate-limit
  /// allows it. No-op on web/desktop or when [isPremium] is true.
  Future<void> showInterstitial({bool isPremium = false}) async {
    if (isPremium) return;
    if (!_isMobilePlatform) return;
    if (!_initialized) await init();

    // Reset daily counter at day rollover.
    final today = _today();
    if (today != _dayBucket) {
      _dayBucket = today;
      _shownToday = 0;
    }
    if (_shownToday >= _maxPerDay) return;
    if (_lastShown != null && DateTime.now().difference(_lastShown!) < _minInterval) return;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
    _lastShown = DateTime.now();
    _shownToday++;
    _loadInterstitial();
  }
}

/// Widget that displays the AdMob banner when one is available, and renders
/// nothing (zero size) on web/desktop or when [shouldShow] is false.
class AdBannerWidget extends StatefulWidget {
  final bool shouldShow;
  const AdBannerWidget({super.key, required this.shouldShow});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shouldShow != widget.shouldShow) {
      if (widget.shouldShow) {
        _load();
      } else {
        _ad?.dispose();
        _ad = null;
        if (mounted) setState(() => _loaded = false);
      }
    }
  }

  Future<void> _load() async {
    if (!widget.shouldShow) return;
    final ad = await AdService.instance.buildBannerAd();
    if (!mounted) {
      ad?.dispose();
      return;
    }
    if (ad != null) {
      _ad = ad;
      setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldShow || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
