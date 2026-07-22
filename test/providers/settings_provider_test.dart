import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('syncEnabledProvider Tests', () {
    test('returns default value of true when not previously set in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      final result = await container.read(syncEnabledProvider.future);
      expect(result, isTrue);
    });

    test('returns correct value when set to false in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'sync_enabled': false});
      final container = createContainer();

      final result = await container.read(syncEnabledProvider.future);
      expect(result, isFalse);
    });

    test('toggle() switches value and updates SharedPreferences and provider state', () async {
      SharedPreferences.setMockInitialValues({'sync_enabled': true});
      final container = createContainer();

      // We listen to the provider to keep it active and alive
      container.listen<AsyncValue<bool>>(syncEnabledProvider, (_, __) {});

      final initial = await container.read(syncEnabledProvider.future);
      expect(initial, isTrue);

      await container.read(syncEnabledProvider.notifier).toggle();

      final toggled = await container.read(syncEnabledProvider.future);
      expect(toggled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sync_enabled'), isFalse);

      // Toggle again
      await container.read(syncEnabledProvider.notifier).toggle();
      final toggledBack = await container.read(syncEnabledProvider.future);
      expect(toggledBack, isTrue);
      expect(prefs.getBool('sync_enabled'), isTrue);
    });
  });

  group('defaultHourlyRateProvider Tests', () {
    test('returns default value of 0.0 when not previously set in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      final result = await container.read(defaultHourlyRateProvider.future);
      expect(result, 0.0);
    });

    test('returns correct value when set in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'default_hourly_rate': 45.5});
      final container = createContainer();

      final result = await container.read(defaultHourlyRateProvider.future);
      expect(result, 45.5);
    });

    test('updateRate() updates SharedPreferences and provider state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      container.listen<AsyncValue<double>>(defaultHourlyRateProvider, (_, __) {});

      final initial = await container.read(defaultHourlyRateProvider.future);
      expect(initial, 0.0);

      await container.read(defaultHourlyRateProvider.notifier).updateRate(75.25);

      final updated = await container.read(defaultHourlyRateProvider.future);
      expect(updated, 75.25);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('default_hourly_rate'), 75.25);
    });
  });

  group('isPremiumProvider Tests', () {
    test('returns default value of false when not previously set in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      final result = await container.read(isPremiumProvider.future);
      expect(result, isFalse);
    });

    test('returns correct value when set to true in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});
      final container = createContainer();

      final result = await container.read(isPremiumProvider.future);
      expect(result, isTrue);
    });

    test('setPremium(), enablePremium(), and disablePremium() update SharedPreferences and provider state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      container.listen<AsyncValue<bool>>(isPremiumProvider, (_, __) {});

      final initial = await container.read(isPremiumProvider.future);
      expect(initial, isFalse);

      final prefs = await SharedPreferences.getInstance();

      // Test enablePremium()
      await container.read(isPremiumProvider.notifier).enablePremium();
      expect(await container.read(isPremiumProvider.future), isTrue);
      expect(prefs.getBool('is_premium'), isTrue);

      // Test disablePremium()
      await container.read(isPremiumProvider.notifier).disablePremium();
      expect(await container.read(isPremiumProvider.future), isFalse);
      expect(prefs.getBool('is_premium'), isFalse);

      // Test setPremium(true)
      await container.read(isPremiumProvider.notifier).setPremium(true);
      expect(await container.read(isPremiumProvider.future), isTrue);
      expect(prefs.getBool('is_premium'), isTrue);
    });
  });

  group('currencyProvider Tests', () {
    test('returns default value of "TL" when not previously set in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      final result = await container.read(currencyProvider.future);
      expect(result, 'TL');
    });

    test('returns correct value when set in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'currency': 'USD'});
      final container = createContainer();

      final result = await container.read(currencyProvider.future);
      expect(result, 'USD');
    });

    test('setCurrency() updates SharedPreferences and provider state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      container.listen<AsyncValue<String>>(currencyProvider, (_, __) {});

      final initial = await container.read(currencyProvider.future);
      expect(initial, 'TL');

      await container.read(currencyProvider.notifier).setCurrency('EUR');

      final updated = await container.read(currencyProvider.future);
      expect(updated, 'EUR');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('currency'), 'EUR');
    });
  });
}
