import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:worklog/core/constants.dart';

void main() {
  group('AppConstants AdMob config tests', () {
    test('should fall back to default test IDs when dotenv is empty', () {
      // Clear or load empty env
      dotenv.testLoad(fileInput: '');

      expect(AppConstants.admobAppId, equals('ca-app-pub-3940256099942544~3347511713'));
      expect(AppConstants.admobBannerUnitId, equals('ca-app-pub-3940256099942544/6300978111'));
      expect(AppConstants.admobInterstitialUnitId, equals('ca-app-pub-3940256099942544/1033173712'));
    });

    test('should resolve values from dotenv when present', () {
      dotenv.testLoad(fileInput: '''
ADMOB_APP_ID=custom-app-id
ADMOB_BANNER_ID=custom-banner-id
ADMOB_INTERSTITIAL_ID=custom-interstitial-id
''');

      expect(AppConstants.admobAppId, equals('custom-app-id'));
      expect(AppConstants.admobBannerUnitId, equals('custom-banner-id'));
      expect(AppConstants.admobInterstitialUnitId, equals('custom-interstitial-id'));
    });
  });
}
