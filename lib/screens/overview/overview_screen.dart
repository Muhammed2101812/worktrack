import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/dimens.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../providers/entries_provider.dart';
import '../../providers/payments_provider.dart';
import '../../providers/settings_provider.dart';

/// "Genel Bakış" — a clean overview that shows the key financial numbers at a
/// glance and two large cards to jump into the full History / Finance detail
/// pages. Intentionally minimal so it complements (not duplicates) the Home
/// screen's "today summary + recent entries" view.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final entriesAsync = ref.watch(entriesProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final currency = ref.watch(currencyProvider).valueOrNull ?? 'TL';

    return Scaffold(
      backgroundColor: Colors.transparent, // Let HomeShell handle bg
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: entriesAsync.when(
          data: (entries) => paymentsAsync.when(
            data: (payments) {
              // Aggregate metrics.
              double totalEarned = 0;
              double totalHours = 0;
              for (final e in entries) {
                totalEarned += e.effectivePrice;
                totalHours += e.durationHours;
              }
              double totalReceived = 0;
              for (final p in payments) {
                totalReceived += p.amount;
              }
              final remaining = totalEarned - totalReceived;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                    children: [
                      // Header
                      ScreenHeader(
                        title: 'Genel Bakış',
                        onBack: () => context.go('/home'),
                      ),
                      const SizedBox(height: 24),

                      // Hero balance card
                      MidnightCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kalan Alacak',
                              style: AppTexts.eyebrow(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${remaining.toStringAsFixed(1)} $currency',
                              style: AppTexts.figureLg(context).copyWith(
                                color: remaining > 0 ? c.orange : c.emerald,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: remaining > 0
                                    ? c.orange.withValues(alpha: 0.1)
                                    : c.emerald.withValues(alpha: 0.1),
                                borderRadius: Radii.xsBr,
                              ),
                              child: Text(
                                remaining > 0
                                    ? 'Ödeme Bekliyor'
                                    : 'Tümü Tahsil Edildi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      remaining > 0 ? c.orange : c.emerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Three metric tiles
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Hakediş',
                              value:
                                  '${totalEarned.toStringAsFixed(0)} $currency',
                              icon: PhosphorIcons.chartLineUp(),
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricTile(
                              label: 'Tahsil edilen',
                              value:
                                  '${totalReceived.toStringAsFixed(0)} $currency',
                              icon: PhosphorIcons.handCoins(),
                              color: c.emerald,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricTile(
                              label: 'Toplam saat',
                              value: '${totalHours.toStringAsFixed(0)} sa',
                              icon: PhosphorIcons.timer(),
                              color: c.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Two large navigation cards
                      Row(
                        children: [
                          Expanded(
                            child: _NavCard(
                              icon: PhosphorIcons.clockCounterClockwise(
                                  PhosphorIconsStyle.fill),
                              title: 'İş Geçmişi',
                              subtitle:
                                  '${entries.length} kayıt',
                              onTap: () => context.push('/home/history'),
                              accent: c.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NavCard(
                              icon: PhosphorIcons
                                  .wallet(PhosphorIconsStyle.fill),
                              title: 'Finans',
                              subtitle: '${payments.length} ödeme',
                              onTap: () => context.push('/home/finance'),
                              accent: c.emerald,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context)
                        .extension<AppPalette>()!
                        .primary)),
            error: (e, _) => Center(
                child: Text('Ödemeler yüklenemedi: $e',
                    style: TextStyle(color: c.textMain))),
          ),
          loading: () => Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context)
                      .extension<AppPalette>()!
                      .primary)),
          error: (e, _) => Center(
              child: Text('İş kayıtları yüklenemedi: $e',
                  style: TextStyle(color: c.textMain))),
        ),
      ),
    );
  }
}

/// Compact metric tile used in the overview's three-up row.
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MidnightCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: c.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: c.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large tappable card that jumps into a detail page.
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: MidnightCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.textMain,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
