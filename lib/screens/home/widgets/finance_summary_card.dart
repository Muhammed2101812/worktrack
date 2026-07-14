import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/dimens.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/payment.dart';
import '../../../models/work_entry.dart';

/// Reusable financial summary card showing remaining balance, total earned
/// (hakediş) and total received payments. Used on both the Overview screen
/// and the Finance screen so the metric stays consistent.
///
/// When [onTap] is provided the whole card is tappable (e.g. to navigate to
/// the full Finance screen).
class FinanceSummaryCard extends StatelessWidget {
  final List<WorkEntry> entries;
  final List<Payment> payments;
  final String currency;
  final VoidCallback? onTap;

  const FinanceSummaryCard({
    super.key,
    required this.entries,
    required this.payments,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    double totalEarned = 0.0;
    for (final e in entries) {
      totalEarned += e.effectivePrice;
    }

    double totalReceived = 0.0;
    for (final p in payments) {
      totalReceived += p.amount;
    }

    final double remainingBalance = totalEarned - totalReceived;

    final card = AppCard(
      padding: const EdgeInsets.all(Spacing.s20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kalan Alacak',
                style: AppTexts.eyebrow(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: remainingBalance > 0
                      ? c.orange.withValues(alpha: 0.1)
                      : c.emerald.withValues(alpha: 0.1),
                  borderRadius: Radii.xsBr,
                ),
                child: Text(
                  remainingBalance > 0 ? 'Ödeme Bekliyor' : 'Tümü Tahsil Edildi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: remainingBalance > 0 ? c.orange : c.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${remainingBalance.toStringAsFixed(1)} $currency',
              style: AppTexts.figureLg(context).copyWith(
                color: remainingBalance > 0 ? c.orange : c.textMain,
              ),
            ),
          ),
          const SizedBox(height: Spacing.s20),
          Container(
            height: 1,
            color: c.cardBorder,
          ),
          const SizedBox(height: Spacing.s16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Hakediş',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalEarned.toStringAsFixed(1)} $currency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: c.cardBorder,
              ),
              const SizedBox(width: Spacing.s24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alınan Ödeme',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalReceived.toStringAsFixed(1)} $currency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          card,
          Positioned(
            top: 14,
            right: 14,
            child: Icon(
              PhosphorIcons.caretRight(),
              color: c.textMuted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
