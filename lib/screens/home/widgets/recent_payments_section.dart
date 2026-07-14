import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dimens.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/payment.dart';

/// "Son Ödemeler" section reused by the Overview screen. Shows a header with a
/// "Tümünü Gör" link (navigates to the Finance screen) followed by up to
/// [limit] recent payments. Renders nothing actionable when there are no
/// payments yet (the empty state is intentionally minimal).
class RecentPaymentsSection extends StatelessWidget {
  final List<Payment> payments;
  final String currency;
  final int limit;

  const RecentPaymentsSection({
    super.key,
    required this.payments,
    required this.currency,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Newest payments first.
    final sorted = [...payments]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = sorted.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: SectionHeader(
            title: 'Son Ödemeler',
            actionLabel: 'Tümünü Gör',
            onAction: () => context.push('/home/finance'),
          ),
        ),
        const SizedBox(height: Spacing.s8),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.s16),
            child: Center(
              child: Text(
                'Henüz ödeme yok',
                style: TextStyle(color: c.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          ...recent.map((payment) => _buildPaymentTile(payment, c)),
      ],
    );
  }

  Widget _buildPaymentTile(Payment payment, AppPalette c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              name: payment.clientName,
              hexColor: payment.clientColor,
              size: AvatarSize.sm,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.clientName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: c.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payment.date,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '+${payment.amount.toStringAsFixed(1)} $currency',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: c.emerald,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
