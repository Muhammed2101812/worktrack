import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/midnight_widgets.dart';
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

  Color _parseColor(String hex, AppPalette c) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.isEmpty) return c.primary;
      final value = int.parse(clean.length == 6 ? 'FF$clean' : clean);
      return Color(value);
    } catch (_) {
      return c.primary;
    }
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Ödemeler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textMain,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/home/finance'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      PhosphorIcons.caretRight(),
                      color: c.primary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
    final color = _parseColor(payment.clientColor, c);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MidnightCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  payment.clientName.isNotEmpty
                      ? payment.clientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
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
