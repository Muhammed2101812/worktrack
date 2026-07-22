import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'WorkLog';

  /// Loads configuration values from the bundled `.env` asset.
  /// Must be called once at startup (see `main.dart`) before reading any value.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // The .env asset is optional in test/CI environments. When it is missing
      // we fall back to compile-time environment overrides (or empty strings),
      // so the app never crashes on config; callers should validate presence.
      debugPrint('AppConstants.load: .env not loaded ($e)');
    }
  }

  static String get supabaseUrl =>
      dotenv.maybeGet('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL');

  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get googleServerClientId =>
      dotenv.maybeGet('GOOGLE_SERVER_CLIENT_ID') ??
      const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static const String entriesTable = 'work_entries';
  static const String clientsTable = 'clients';
  static const String projectsTable = 'projects';
  static const String paymentsTable = 'payments';

  static const List<String> workTypes = ['Grafik', 'Yazılım', 'Diğer'];

  static const List<String> clientColors = [
    '#4A90D9', '#50C878', '#FF6B6B', '#FFB347',
    '#9B59B6', '#1ABC9C', '#E67E22', '#E91E63',
  ];

  /// Supported currency codes for the global currency setting.
  static const List<String> currencies = ['TL', 'USD', 'EUR', 'GBP'];

  // ── Advertising (AdMob) ──────────────────────────────────────────────────
  //
  // These use Google's official test ad unit IDs by default so the app is
  // fully functional during development. They are loaded from the bundled
  // `.env` asset or via compile-time environment overrides.
  static String get admobAppId =>
      dotenv.maybeGet('ADMOB_APP_ID') ??
      const String.fromEnvironment('ADMOB_APP_ID', defaultValue: 'ca-app-pub-3940256099942544~3347511713');

  static String get admobBannerUnitId =>
      dotenv.maybeGet('ADMOB_BANNER_ID') ??
      const String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: 'ca-app-pub-3940256099942544/6300978111');

  static String get admobInterstitialUnitId =>
      dotenv.maybeGet('ADMOB_INTERSTITIAL_ID') ??
      const String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: 'ca-app-pub-3940256099942544/1033173712');

  // ── In-App Purchase ──────────────────────────────────────────────────────
  /// Product id for the one-time "remove ads" purchase. Must match the
  /// product created in the Play Console / App Store Connect.
  static const String iapRemoveAdsProductId = 'worktrack_remove_ads';
  static const List<String> iapProductIds = [iapRemoveAdsProductId];
}
