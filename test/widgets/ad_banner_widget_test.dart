import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worklog/services/ad_service.dart';

class MockBannerAd extends Mock implements BannerAd {
  @override
  AdSize get size => AdSize.banner;

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdService adService;

  setUp(() {
    adService = AdService.instance;
    adService.reset();
    AdBannerWidget.adWidgetBuilder = (ad) => Container(key: const Key('mock_ad_widget'));
  });

  tearDown(() {
    adService.reset();
    AdBannerWidget.adWidgetBuilder = null;
  });

  group('AdBannerWidget Tests', () {
    testWidgets('renders nothing (SizedBox.shrink) when shouldShow is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdBannerWidget(shouldShow: false),
            ),
          ),
        ),
      );

      await tester.pump();

      // Expect that we do not find the mock ad widget
      expect(find.byKey(const Key('mock_ad_widget')), findsNothing);

      // SizedBox.shrink is represented as a SizedBox with height 0 and width 0
      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsOneWidget);
      final SizedBox sizedBox = tester.widget(sizedBoxFinder);
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });

    testWidgets('renders nothing when shouldShow is true but ad loading fails (returns null)',
        (WidgetTester tester) async {
      adService.isMobilePlatformOverride = true;
      adService.mobileAdsInitializer = () async {};
      adService.bannerAdLoader = () async => null;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdBannerWidget(shouldShow: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mock_ad_widget')), findsNothing);
    });

    testWidgets('renders Mock Ad Widget inside a SizedBox when shouldShow is true and ad loading succeeds',
        (WidgetTester tester) async {
      adService.isMobilePlatformOverride = true;
      adService.mobileAdsInitializer = () async {};

      final mockBanner = MockBannerAd();
      adService.bannerAdLoader = () async => mockBanner;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdBannerWidget(shouldShow: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that mock ad widget is rendered
      expect(find.byKey(const Key('mock_ad_widget')), findsOneWidget);

      // Verify the parent SizedBox height matches the ad size height (50.0)
      final sizedBoxFinder = find.byType(SizedBox);
      final SizedBox sizedBox = tester.widget(sizedBoxFinder);
      expect(sizedBox.height, 50.0);
    });
  });
}
