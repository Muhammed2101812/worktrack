import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme.dart';
import '../../providers/entries_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import 'widgets/today_summary_card.dart';
import 'widgets/entry_list_tile.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.contains('/history')) {
      currentIndex = 1;
    } else if (location.contains('/stats')) {
      currentIndex = 2;
    } else if (location.contains('/settings')) {
      currentIndex = 3;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;

          if (isWide) {
            return Row(
              children: [
                _buildSidebar(context, ref, currentIndex),
                Expanded(child: child),
              ],
            );
          }

          return Stack(
            children: [
              child,
              Positioned(
                left: 24,
                right: 24,
                bottom: 30,
                child: _buildCustomNavbar(context, currentIndex),
              ),
              Positioned(
                bottom: 55,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.go('/home/add'),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, int currentIndex) {
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
        label: 'Raporlar',
        icon: PhosphorIcons.chartPie(),
        activeIcon: PhosphorIcons.chartPie(PhosphorIconsStyle.fill),
        index: 2,
        route: '/home/stats',
      ),
      _NavItemData(
        label: 'Ayarlar',
        icon: PhosphorIcons.gear(),
        activeIcon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
        index: 3,
        route: '/home/settings',
      ),
    ];

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
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
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.timer(),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'WorkTrack',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // New record button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/home/add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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

          const Divider(color: AppColors.border, height: 1),

          // Footer: user profile
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(
                        color: AppColors.primary,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  icon: Icon(
                    PhosphorIcons.signOut(),
                    color: AppColors.textMuted,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavbar(BuildContext context, int currentIndex) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: PhosphorIcons.house(),
                  activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: PhosphorIcons.clockCounterClockwise(),
                  activeIcon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/home/history'),
                ),
                
                // Central FAB Placeholder/Spacer
                const SizedBox(width: 70),

                _buildNavItem(
                  context,
                  index: 2,
                  icon: PhosphorIcons.chartPie(),
                  activeIcon: PhosphorIcons.chartPie(PhosphorIconsStyle.fill),
                  isActive: currentIndex == 2,
                  onTap: () => context.go('/home/stats'),
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: PhosphorIcons.gear(),
                  activeIcon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/home/settings'),
                ),
              ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
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
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Row(
                children: [
                  Icon(Icons.backup_outlined, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text('Veri Kurtarma', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              content: Text(
                'Uygulamada kayıtlı veri bulunamadı ancak yerel bir yedek tespit edildi ($displayTime).\n\nVerilerinizi bu yedeklemeden geri yüklemek ister misiniz?',
                style: const TextStyle(height: 1.4, color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hayır, Yeni Başla', style: TextStyle(color: AppColors.textMuted)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  child: const Text('Evet, Geri Yükle', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
        final isWide = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: Colors.transparent, // Let HomeShell handle bg
          extendBodyBehindAppBar: true,
          appBar: isWide
              ? null
              : AppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba,',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            avatarLetter,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          body: entriesAsync.when(
            data: (entries) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    isWide ? 40 : 120,
                    24,
                    isWide ? 40 : 150,
                  ),
                  children: [
                    const TodaySummaryCard(),
                    const SizedBox(height: 35),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Son Kayıtlar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/home/history'),
                          child: const Text(
                            'Tümünü Gör',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (entries.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('Henüz kayıt bulunmuyor'),
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
        );
      },
    );
  }
}
