import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worklog/services/ad_service.dart';

class MockInterstitialAd extends Mock implements InterstitialAd {}
class FakeFullScreenContentCallback extends Fake implements FullScreenContentCallback {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeFullScreenContentCallback());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_mobile_ads'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  setUp(() {
    AdService.instance.resetForTesting();
  });

  tearDown(() {
    AdService.instance.resetForTesting();
  });

  group('AdService Unit Tests', () {
    test('init should gracefully catch exceptions during MobileAds initialization', () async {
      AdService.isMobilePlatformOverride = true;

      // Force initializer to throw an exception
      AdService.instance.mobileAdsInitializer = () async {
        throw Exception('Initialization failed simulation');
      };

      // Ensure that calling init does not bubble up the exception
      expect(() async => await AdService.instance.init(), returnsNormally);
    });

    test('init should not execute when not on mobile platform', () async {
      AdService.isMobilePlatformOverride = false;
      bool initializerCalled = false;

      AdService.instance.mobileAdsInitializer = () async {
        initializerCalled = true;
        return InitializationStatus({});
      };

      await AdService.instance.init();
      expect(initializerCalled, isFalse);
    });

    test('init on mobile platform successfully initialises and triggers interstitial load', () async {
      AdService.isMobilePlatformOverride = true;
      bool initializerCalled = false;
      bool loaderCalled = false;

      AdService.instance.mobileAdsInitializer = () async {
        initializerCalled = true;
        return InitializationStatus({});
      };

      AdService.instance.interstitialAdLoader = ({
        required String adUnitId,
        required AdRequest request,
        required InterstitialAdLoadCallback adLoadCallback,
      }) {
        loaderCalled = true;
      };

      await AdService.instance.init();
      expect(initializerCalled, isTrue);
      expect(loaderCalled, isTrue);
    });

    test('interstitial load should handle successful ad loading and show ad correctly', () async {
      AdService.isMobilePlatformOverride = true;
      final mockAd = MockInterstitialAd();

      when(() => mockAd.fullScreenContentCallback = any()).thenAnswer((_) {});
      when(() => mockAd.show()).thenAnswer((_) => Future.value());

      AdService.instance.mobileAdsInitializer = () async => InitializationStatus({});

      // Simulate successful loading
      AdService.instance.interstitialAdLoader = ({
        required String adUnitId,
        required AdRequest request,
        required InterstitialAdLoadCallback adLoadCallback,
      }) {
        adLoadCallback.onAdLoaded(mockAd);
      };

      await AdService.instance.init();

      // Show the loaded ad
      await AdService.instance.showInterstitial();

      // Verify that the ad's callbacks and show method are triggered
      verify(() => mockAd.fullScreenContentCallback = any()).called(1);
      verify(() => mockAd.show()).called(1);
    });

    test('interstitial load should handle ad loading failure callback correctly', () async {
      AdService.isMobilePlatformOverride = true;
      AdService.instance.mobileAdsInitializer = () async => InitializationStatus({});

      final testError = LoadAdError(1, 'domain', 'Test error message', null);
      bool onAdFailedToLoadCalled = false;

      // Simulate failing to load
      AdService.instance.interstitialAdLoader = ({
        required String adUnitId,
        required AdRequest request,
        required InterstitialAdLoadCallback adLoadCallback,
      }) {
        adLoadCallback.onAdFailedToLoad(testError);
        onAdFailedToLoadCalled = true;
      };

      await AdService.instance.init();
      expect(onAdFailedToLoadCalled, isTrue);

      // Attempting to show should trigger load again because there is no ad
      bool loaderCalledAgain = false;
      AdService.instance.interstitialAdLoader = ({
        required String adUnitId,
        required AdRequest request,
        required InterstitialAdLoadCallback adLoadCallback,
      }) {
        loaderCalledAgain = true;
      };

      await AdService.instance.showInterstitial();
      expect(loaderCalledAgain, isTrue);
    });
  });
}
