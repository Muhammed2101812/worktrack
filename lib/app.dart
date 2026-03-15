import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'WorkTrack',
      theme: AppTheme.light,
      darkTheme: AppTheme.light, // Her iki durumda da light tema kullanılması için
      themeMode: ThemeMode.light, // Tema modunu light olarak zorla
      routerConfig: router,
    );
  }
}
