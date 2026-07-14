import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/overview/overview_screen.dart';
import '../screens/add_entry/add_entry_screen.dart';
import '../models/work_entry.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/finance/finance_screen.dart';

/// Builds a [CustomTransitionPage] with an instant (no animation) swap so the
/// background colour doesn't flash a lighter tint during route transitions.
/// The default Material fade-in briefly shows scaffoldBackgroundColor before
/// the page's own (transparent) background settles, which looks like a flash.
Page<void> _noFlashPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (_, __, ___, child) => child,
  );
}

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
        pageBuilder: (context, state) {
          final entryToEdit = state.extra as WorkEntry?;
          return _noFlashPage(AddEntryScreen(entryToEdit: entryToEdit));
        },
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (_, __) => _noFlashPage(const HomeScreen())),
          GoRoute(path: '/home/overview', pageBuilder: (_, __) => _noFlashPage(const OverviewScreen())),
          GoRoute(path: '/home/history', pageBuilder: (_, __) => _noFlashPage(const HistoryScreen())),
          GoRoute(path: '/home/finance', pageBuilder: (_, __) => _noFlashPage(const FinanceScreen())),
          GoRoute(path: '/home/stats', pageBuilder: (_, __) => _noFlashPage(const StatsScreen())),
          GoRoute(path: '/home/settings', pageBuilder: (_, __) => _noFlashPage(const SettingsScreen())),
        ],
      ),
    ],
  );
});