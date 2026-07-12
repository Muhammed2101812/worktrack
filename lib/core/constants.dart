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
}
