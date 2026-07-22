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

  group('SyncEnabledNotifier Tests', () {
    test('default value when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      final val = await container.read(syncEnabledProvider.future);
      expect(val, isTrue);
    });

    test('initial value loaded from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'sync_enabled': false});
      final container = createContainer();

      final val = await container.read(syncEnabledProvider.future);
      expect(val, isFalse);
    });

    test('toggle changes sync status and writes to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'sync_enabled': true});
      final container = createContainer();

      // Read initial state first to trigger build
      expect(await container.read(syncEnabledProvider.future), isTrue);

      // Perform toggle
      await container.read(syncEnabledProvider.notifier).toggle();

      // Check updated provider state
      expect(await container.read(syncEnabledProvider.future), isFalse);

      // Check updated shared_preferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sync_enabled'), isFalse);
    });
  });

  group('DefaultHourlyRateNotifier Tests', () {
    test('default value when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      final val = await container.read(defaultHourlyRateProvider.future);
      expect(val, equals(0.0));
    });

    test('initial value loaded from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'default_hourly_rate': 45.5});
      final container = createContainer();

      final val = await container.read(defaultHourlyRateProvider.future);
      expect(val, equals(45.5));
    });

    test('updateRate changes default hourly rate and writes to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'default_hourly_rate': 0.0});
      final container = createContainer();

      expect(await container.read(defaultHourlyRateProvider.future), equals(0.0));

      await container.read(defaultHourlyRateProvider.notifier).updateRate(75.0);

      expect(await container.read(defaultHourlyRateProvider.future), equals(75.0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('default_hourly_rate'), equals(75.0));
    });
  });

  group('IsPremiumNotifier Tests', () {
    test('default value when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      final val = await container.read(isPremiumProvider.future);
      expect(val, isFalse);
    });

    test('initial value loaded from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});
      final container = createContainer();

      final val = await container.read(isPremiumProvider.future);
      expect(val, isTrue);
    });

    test('setPremium/enablePremium/disablePremium changes premium status and writes to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'is_premium': false});
      final container = createContainer();

      expect(await container.read(isPremiumProvider.future), isFalse);

      await container.read(isPremiumProvider.notifier).enablePremium();
      expect(await container.read(isPremiumProvider.future), isTrue);

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium'), isTrue);

      await container.read(isPremiumProvider.notifier).disablePremium();
      expect(await container.read(isPremiumProvider.future), isFalse);

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium'), isFalse);

      await container.read(isPremiumProvider.notifier).setPremium(true);
      expect(await container.read(isPremiumProvider.future), isTrue);

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium'), isTrue);
    });
  });

  group('CurrencyNotifier Tests', () {
    test('default value when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();

      final val = await container.read(currencyProvider.future);
      expect(val, equals('TL'));
    });

    test('initial value loaded from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'currency': 'USD'});
      final container = createContainer();

      final val = await container.read(currencyProvider.future);
      expect(val, equals('USD'));
    });

    test('setCurrency changes currency and writes to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'currency': 'TL'});
      final container = createContainer();

      expect(await container.read(currencyProvider.future), equals('TL'));

      await container.read(currencyProvider.notifier).setCurrency('EUR');

      expect(await container.read(currencyProvider.future), equals('EUR'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('currency'), equals('EUR'));
    });
  });
}
