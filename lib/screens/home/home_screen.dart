import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme.dart';
import '../../providers/entries_provider.dart';
import '../../providers/auth_provider.dart';
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
      body: Stack(
        children: [
          // Content Area
          child,

          // Custom Floating Navbar
          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: _buildCustomNavbar(context, currentIndex),
          ),

          // Central FAB — rendered after navbar so it sits on top
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final currentUser = ref.watch(authNotifierProvider);
    final displayName = currentUser?.email?.split('@').first ?? 'Kullanıcı';
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K';

    return Scaffold(
      backgroundColor: Colors.transparent, // Let HomeShell handle bg
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
            data: (entries) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 150), // Extra bottom padding for floating nav
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Hata: $e')),
      ),
    );
  }
}

