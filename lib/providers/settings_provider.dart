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

/// Whether the user has purchased the premium upgrade (currently: removes ads).
/// Persisted in SharedPreferences and toggled by [IapService] on a successful
/// purchase / restore.
final isPremiumProvider =
    AsyncNotifierProvider<IsPremiumNotifier, bool>(IsPremiumNotifier.new);

class IsPremiumNotifier extends AsyncNotifier<bool> {
  static const _key = 'is_premium';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    state = AsyncData(value);
  }

  Future<void> enablePremium() => setPremium(true);
  Future<void> disablePremium() => setPremium(false);
}

/// Global currency code used across the app for displaying monetary amounts.
/// Stored as a string in SharedPreferences. NOTE: changing the currency only
/// relabels existing amounts — it does NOT convert them (e.g. 100 stored
/// units shown as "100 TL" will become "100 USD" after switching). The UI
/// warns the user about this before applying the change.
final currencyProvider =
    AsyncNotifierProvider<CurrencyNotifier, String>(CurrencyNotifier.new);

class CurrencyNotifier extends AsyncNotifier<String> {
  static const _key = 'currency';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'TL';
  }

  Future<void> setCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    state = AsyncData(code);
  }
}
