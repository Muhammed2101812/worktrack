import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worklog/services/ad_service.dart';

class MockBannerAd extends Mock implements BannerAd {}
class MockInterstitialAd extends Mock implements InterstitialAd {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdService Tests', () {
    late AdService adService;

    setUp(() {
      adService = AdService.instance;
      adService.reset();
    });

    tearDown(() {
      adService.reset();
    });

    group('Non-Mobile Platform Tests', () {
      setUp(() {
        adService.isMobilePlatformOverride = false;
      });

      test('init does not initialize on non-mobile', () async {
        bool initializedCalled = false;
        adService.mobileAdsInitializer = () async {
          initializedCalled = true;
        };

        await adService.init();
        expect(initializedCalled, isFalse);
      });

      test('buildBannerAd returns null on non-mobile', () async {
        final banner = await adService.buildBannerAd();
        expect(banner, isNull);
      });

      test('showInterstitial does nothing on non-mobile', () async {
        bool initCalled = false;
        adService.mobileAdsInitializer = () async {
          initCalled = true;
        };
        await adService.showInterstitial();
        expect(initCalled, isFalse);
      });
    });

    group('Mobile Platform Tests', () {
      setUp(() {
        adService.isMobilePlatformOverride = true;
        // Default dummy loader to prevent actual platform calls to InterstitialAd.load
        adService.interstitialAdLoader = ({
          required adUnitId,
          required request,
          required adLoadCallback,
        }) {};
      });

      test('init initializes successfully and triggers load', () async {
        bool initCalled = false;
        bool loadCalled = false;

        adService.mobileAdsInitializer = () async {
          initCalled = true;
        };
        adService.interstitialAdLoader = ({
          required adUnitId,
          required request,
          required adLoadCallback,
        }) {
          loadCalled = true;
        };

        await adService.init();
        expect(initCalled, isTrue);
        expect(loadCalled, isTrue);
      });

      test('init handles error gracefully', () async {
        adService.mobileAdsInitializer = () async {
          throw Exception('Initialization failed');
        };

        await expectLater(adService.init(), completes);
      });

      test('buildBannerAd returns BannerAd on success', () async {
        final mockBanner = MockBannerAd();
        adService.mobileAdsInitializer = () async {};
        adService.bannerAdLoader = () async => mockBanner;

        final banner = await adService.buildBannerAd();
        expect(banner, equals(mockBanner));
      });

      test('buildBannerAd returns null on failure', () async {
        adService.mobileAdsInitializer = () async {};
        adService.bannerAdLoader = () async => null;

        final banner = await adService.buildBannerAd();
        expect(banner, isNull);
      });

      test('showInterstitial short circuits when isPremium is true', () async {
        bool initCalled = false;
        adService.mobileAdsInitializer = () async {
          initCalled = true;
        };

        await adService.showInterstitial(isPremium: true);
        expect(initCalled, isFalse);
      });

      test('showInterstitial and FullScreenContentCallback flows', () async {
        final mockInterstitial = MockInterstitialAd();
        adService.mobileAdsInitializer = () async {};

        FullScreenContentCallback<InterstitialAd>? registeredCallback;
        when(() => mockInterstitial.fullScreenContentCallback = any())
            .thenAnswer((invocation) {
          registeredCallback = invocation.positionalArguments[0] as FullScreenContentCallback<InterstitialAd>?;
        });
        when(() => mockInterstitial.show()).thenAnswer((_) async {});
        when(() => mockInterstitial.dispose()).thenAnswer((_) async {});

        // Setup loaded ad
        adService.interstitialAdLoader = ({
          required adUnitId,
          required request,
          required adLoadCallback,
        }) {
          adLoadCallback.onAdLoaded(mockInterstitial);
        };

        // Initialize to trigger load
        await adService.init();

        // Change the loader BEFORE calling showInterstitial, so that the load triggered at the end of showInterstitial
        // (and subsequent callbacks) uses this new loader!
        bool secondLoadTriggered = false;
        adService.interstitialAdLoader = ({
          required adUnitId,
          required request,
          required adLoadCallback,
        }) {
          secondLoadTriggered = true;
          // complete the load (or fail it) to reset _interstitialLoading to false
          adLoadCallback.onAdFailedToLoad(LoadAdError(0, 'mock-domain', 'mock-error', null));
        };

        // Show ad
        await adService.showInterstitial(isPremium: false);

        verify(() => mockInterstitial.show()).called(1);
        expect(registeredCallback, isNotNull);
        expect(secondLoadTriggered, isTrue);

        // Reset secondLoadTriggered to test the dismissal callback loader trigger
        secondLoadTriggered = false;
        registeredCallback!.onAdDismissedFullScreenContent!(mockInterstitial);
        verify(() => mockInterstitial.dispose()).called(1);
        expect(secondLoadTriggered, isTrue);
      });

      test('showInterstitial respects daily limits and cooldowns', () async {
        final mockInterstitial = MockInterstitialAd();
        adService.mobileAdsInitializer = () async {};

        when(() => mockInterstitial.show()).thenAnswer((_) async {});
        when(() => mockInterstitial.dispose()).thenAnswer((_) async {});

        // Track loader invocation count
        int loadCount = 0;
        adService.interstitialAdLoader = ({
          required adUnitId,
          required request,
          required adLoadCallback,
        }) {
          loadCount++;
          adLoadCallback.onAdLoaded(mockInterstitial);
        };

        // Mock current time
        var currentTime = DateTime(2023, 10, 1, 12, 0);
        adService.currentTimeOverride = () => currentTime;

        await adService.init();
        expect(loadCount, equals(1));

        // 1st impression (allowed)
        await adService.showInterstitial();
        verify(() => mockInterstitial.show()).called(1);

        // Reset show count on mock
        clearInteractions(mockInterstitial);

        // 2nd impression (blocked by cooldown of 2 mins)
        await adService.showInterstitial();
        verifyNever(() => mockInterstitial.show());

        // Fast forward 1 minute (still blocked)
        currentTime = currentTime.add(const Duration(minutes: 1));
        await adService.showInterstitial();
        verifyNever(() => mockInterstitial.show());

        // Fast forward another minute (total 2 mins - allowed)
        currentTime = currentTime.add(const Duration(minutes: 1));
        await adService.showInterstitial();
        verify(() => mockInterstitial.show()).called(1);
        clearInteractions(mockInterstitial);

        // Fast forward 2 minutes for 3rd impression (allowed)
        currentTime = currentTime.add(const Duration(minutes: 2));
        await adService.showInterstitial();
        verify(() => mockInterstitial.show()).called(1);
        clearInteractions(mockInterstitial);

        // Fast forward 2 minutes for 4th impression (blocked by max 3 ads per day limit)
        currentTime = currentTime.add(const Duration(minutes: 2));
        await adService.showInterstitial();
        verifyNever(() => mockInterstitial.show());

        // Rollover to next day (limit reset - allowed!)
        currentTime = currentTime.add(const Duration(hours: 12)); // past midnight
        await adService.showInterstitial();
        verify(() => mockInterstitial.show()).called(1);
      });
    });
  });
}
