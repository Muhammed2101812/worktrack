import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final syncEnabledProvider =
    AsyncNotifierProvider<SyncEnabledNotifier, bool>(SyncEnabledNotifier.new);

class SyncEnabledNotifier extends AsyncNotifier<bool> {
  static const _key = 'sync_enabled';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, !current);
    state = AsyncData(!current);
  }
}

final defaultHourlyRateProvider =
    AsyncNotifierProvider<DefaultHourlyRateNotifier, double>(DefaultHourlyRateNotifier.new);

class DefaultHourlyRateNotifier extends AsyncNotifier<double> {
  static const _key = 'default_hourly_rate';

  @override
  Future<double> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? 0.0;
  }

  Future<void> updateRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, rate);
    state = AsyncData(rate);
  }
}
