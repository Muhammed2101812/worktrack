import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/constants.dart';
import 'providers/theme_provider.dart';
import 'services/iap_service.dart';
import 'services/ad_service.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      Intl.defaultLocale = 'tr_TR';
      // Start loading both locales and constants in parallel.
      await Future.wait([
        initializeDateFormatting(),
        AppConstants.load(),
      ]);

      // Platformlara göre sqflite başlatma
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else if (defaultTargetPlatform == TargetPlatform.windows ||
                 defaultTargetPlatform == TargetPlatform.linux ||
                 defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Initialization error: $e');
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
      // Initialise ads. Runs only on mobile; no-op on web/desktop.
      AdService.instance.init().catchError((e) {
        debugPrint('AdService initialization error: $e');
      });
      // Connect to the store and restore any previous premium purchase.
      // Runs only on mobile; no-op on web/desktop.
      ref.read(iapServiceProvider).init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    if (!_initialized) {
      return MaterialApp(
        title: 'WorkTrack',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'WorkTrack',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
