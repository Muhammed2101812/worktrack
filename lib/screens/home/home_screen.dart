import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../providers/entries_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ad_service.dart';
import 'widgets/today_summary_card.dart';
import 'widgets/entry_list_tile.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.contains('/history')) {
      currentIndex = 1;
    } else if (location.contains('/finance')) {
      currentIndex = 2;
    } else if (location.contains('/stats')) {
      currentIndex = 3;
    } else if (location.contains('/settings')) {
      currentIndex = 4;
    }

    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;
    final showBanner = !isPremium;

    return Scaffold(
      backgroundColor: c.bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;

          if (isWide) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildSidebar(context, ref, currentIndex),
                      Expanded(child: child),
                    ],
                  ),
                ),
                if (showBanner)
                  AdBannerWidget(shouldShow: showBanner),
              ],
            );
          }

          // Narrow: floating navbar stays at bottom:30 as before. The banner
          // (when loaded) sits directly above the system nav bar via SafeArea,
          // without disturbing the existing floating-navbar layout.
          return Stack(
            children: [
              child,
              Positioned(
                left: 24,
                right: 24,
                bottom: 30,
                child: _buildCustomNavbar(context, currentIndex),
              ),
              if (showBanner)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: AdBannerWidget(shouldShow: showBanner),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, int currentIndex) {
    final c = AppColors.of(context);
    final currentUser = ref.watch(authNotifierProvider);
    final metadata = currentUser?.userMetadata;
    String displayName = metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        currentUser?.email?.split('@').first ??
        'Kullanıcı';
    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K';

    final navItems = <_NavItemData>[
      _NavItemData(
        label: 'Ana Sayfa',
        icon: PhosphorIcons.house(),
        activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
        index: 0,
        route: '/home',
      ),
      _NavItemData(
        label: 'İş Geçmişi',
        icon: PhosphorIcons.clockCounterClockwise(),
        activeIcon:
            PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
        index: 1,
        route: '/home/history',
      ),
      _NavItemData(
        label: 'Finans',
        icon: PhosphorIcons.wallet(),
        activeIcon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
        index: 2,
        route: '/home/finance',
      ),
      _NavItemData(
        label: 'Raporlar',
        icon: PhosphorIcons.chartPie(),
        activeIcon: PhosphorIcons.chartPie(PhosphorIconsStyle.fill),
        index: 3,
        route: '/home/stats',
      ),
      _NavItemData(
        label: 'Ayarlar',
        icon: PhosphorIcons.gear(),
        activeIcon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
        index: 4,
        route: '/home/settings',
      ),
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: c.cardBg,
        border: Border(
          right: BorderSide(color: c.cardBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.timer(),
                    color: c.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'WorkTrack',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: c.textMain,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: c.cardBorder, height: 1),

          // New record button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/home/add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Yeni Kayıt',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ),

          // Navigation list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: navItems
                  .map((item) => _buildSidebarNavItem(
                        context,
                        item: item,
                        isActive: currentIndex == item.index,
                      ))
                  .toList(),
            ),
          ),

          Divider(color: c.cardBorder, height: 1),

          // Footer: user profile
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  icon: Icon(
                    PhosphorIcons.signOut(),
                    color: c.textMuted,
                    size: 20,
                  ),
                  tooltip: 'Çıkış Yap',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(
    BuildContext context, {
    required _NavItemData item,
    required bool isActive,
  }) {
    final c = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? c.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? c.primary : c.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? c.primary : c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavbar(BuildContext context, int currentIndex) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: c.cardBg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.cardBorder.withValues(alpha: 0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 0,
                    icon: PhosphorIcons.house(),
                    activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                    isActive: currentIndex == 0,
                    onTap: () => context.go('/home'),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 1,
                    icon: PhosphorIcons.clockCounterClockwise(),
                    activeIcon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
                    isActive: currentIndex == 1,
                    onTap: () => context.go('/home/history'),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 2,
                    icon: PhosphorIcons.wallet(),
                    activeIcon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                    isActive: currentIndex == 2,
                    onTap: () => context.go('/home/finance'),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 3,
                    icon: PhosphorIcons.chartPie(),
                    activeIcon: PhosphorIcons.chartPie(PhosphorIconsStyle.fill),
                    isActive: currentIndex == 3,
                    onTap: () => context.go('/home/stats'),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 4,
                    icon: PhosphorIcons.gear(),
                    activeIcon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
                    isActive: currentIndex == 4,
                    onTap: () => context.go('/home/settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    const navLabels = ['Ana Sayfa', 'Geçmiş', 'Finans', 'Raporlar', 'Ayarlar'];
    return Tooltip(
      message: navLabels[index],
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? c.primary : c.textMuted,
                size: 24,
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final String route;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.route,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(syncProvider.notifier).fullSync();
      ref.read(entriesProvider.notifier).refresh();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAndRestoreBackup();
        }
      });
    });
  }

  Future<void> _checkAndRestoreBackup() async {
    final entriesVal = ref.read(entriesProvider);
    final clientsVal = ref.read(clientsProvider);

    if (entriesVal.value != null && entriesVal.value!.isEmpty &&
        clientsVal.value != null && clientsVal.value!.isEmpty) {
      final backupService = ref.read(backupServiceProvider);
      final backup = await backupService.checkBackup();
      if (backup != null) {
        final timestampStr = backup['timestamp'] as String?;
        String displayTime = '';
        if (timestampStr != null) {
          try {
            final dt = DateTime.parse(timestampStr);
            displayTime = '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {
            displayTime = timestampStr;
          }
        }

        if (mounted) {
          final shouldRestore = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final c = AppColors.of(ctx);
              return AlertDialog(
                backgroundColor: c.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: c.cardBorder, width: 1),
                ),
                title: Row(
                  children: [
                    Icon(Icons.backup_outlined, color: c.primary),
                    const SizedBox(width: 12),
                    Text('Veri Kurtarma', style: TextStyle(fontWeight: FontWeight.bold, color: c.textMain)),
                  ],
                ),
                content: Text(
                  'Uygulamada kayıtlı veri bulunamadı ancak yerel bir yedek tespit edildi ($displayTime).\n\nVerilerinizi bu yedeklemeden geri yüklemek ister misiniz?',
                  style: TextStyle(height: 1.4, color: c.textMuted),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Hayır, Yeni Başla', style: TextStyle(color: c.textMuted)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: c.primary),
                    child: const Text('Evet, Geri Yükle', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );

          if (shouldRestore == true && mounted) {
            try {
              await backupService.restoreBackup(backup);
              ref.invalidate(entriesProvider);
              ref.invalidate(clientsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verileriniz başarıyla yedeklemeden geri yüklendi!')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Geri yükleme başarısız: $e')),
                );
              }
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final currentUser = ref.watch(authNotifierProvider);
    final metadata = currentUser?.userMetadata;
    String displayName = metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        currentUser?.email?.split('@').first ??
        'Kullanıcı';
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K';

    return LayoutBuilder(
      builder: (context, constraints) {
        final c = AppColors.of(context);
        final isWide = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: Colors.transparent, // Let HomeShell handle bg
          extendBodyBehindAppBar: true,
          appBar: null,
          body: entriesAsync.when(
            data: (entries) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    isWide ? 40 : 120,
                  ),
                  children: [
                    // Welcome Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba,',
                              style: TextStyle(
                                fontSize: 14,
                                color: c.textMuted,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                color: c.textMain,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              avatarLetter,
                              style: TextStyle(
                                color: c.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const TodaySummaryCard(),
                    const SizedBox(height: 35),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Son Kayıtlar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.textMain,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/home/history'),
                          child: Text(
                            'Tümünü Gör',
                            style: TextStyle(
                              color: c.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (entries.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: c.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  size: 56,
                                  color: c.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Henüz kaydınız bulunmuyor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: c.textMain,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'İlk çalışma kaydınızı oluşturun',
                                style: TextStyle(color: c.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              MidnightButton(
                                onPressed: () => context.go('/home/add'),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: c.onPrimary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'İlk Kaydını Oluştur',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: c.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...entries.take(5).map((entry) => EntryListTile(entry: entry)).toList(),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Hata: $e')),
          ),
          floatingActionButton: isWide
              ? FloatingActionButton(
                  onPressed: () => context.go('/home/add'),
                  backgroundColor: c.primary,
                  child: Icon(Icons.add, color: c.onPrimary),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: FloatingActionButton(
                    onPressed: () => context.go('/home/add'),
                    backgroundColor: c.primary,
                    child: Icon(Icons.add, color: c.onPrimary),
                  ),
                ),
        );
      },
    );
  }
}
