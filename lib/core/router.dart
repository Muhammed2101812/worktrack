import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/add_entry/add_entry_screen.dart';
import '../models/work_entry.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/finance/finance_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      // AddEntryScreen is a full-screen route OUTSIDE the ShellRoute so it is
      // not overlapped by the floating navbar / FAB (which were blocking the
      // "Kaydı Tamamla" button hit area). It provides its own Scaffold.
      GoRoute(
        path: '/home/add',
        builder: (context, state) {
          final entryToEdit = state.extra as WorkEntry?;
          return AddEntryScreen(entryToEdit: entryToEdit);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/home/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/home/finance', builder: (_, __) => const FinanceScreen()),
          GoRoute(path: '/home/stats', builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/home/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});