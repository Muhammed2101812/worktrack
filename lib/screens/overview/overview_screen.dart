import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme.dart';
import '../../providers/entries_provider.dart';
import '../../providers/payments_provider.dart';
import '../../providers/settings_provider.dart';
import '../home/widgets/finance_summary_card.dart';
import '../home/widgets/recent_entries_section.dart';
import '../home/widgets/recent_payments_section.dart';

/// "Genel Bakış" — a unified overview of work history and finances. Combines
/// the financial summary, recent entries and recent payments so the user can
/// see everything at a glance, then drill into the full History / Finance
/// detail screens via "Tümünü Gör".
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
            data: (payments) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/home'),
                            child: Icon(PhosphorIcons.arrowLeft(),
                                color: c.textMain, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Genel Bakış',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: c.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Financial summary card (tappable → Finance detail)
                    FinanceSummaryCard(
                      entries: entries,
                      payments: payments,
                      currency: currency,
                      onTap: () => context.go('/home/finance'),
                    ),
                    const SizedBox(height: 32),
                    // Recent entries (full list link → History detail)
                    RecentEntriesSection(
                      entries: entries,
                      limit: 5,
                      emptyState: true,
                    ),
                    const SizedBox(height: 32),
                    // Recent payments (full list link → Finance detail)
                    RecentPaymentsSection(
                      payments: payments,
                      currency: currency,
                      limit: 3,
                    ),
                  ],
                ),
              ),
            ),
            loading: () =>
                Center(child: CircularProgressIndicator(color: c.primary)),
            error: (e, _) => Center(
                child: Text('Ödemeler yüklenemedi: $e',
                    style: TextStyle(color: c.textMain))),
          ),
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
              child: Text('İş kayıtları yüklenemedi: $e',
                  style: TextStyle(color: c.textMain))),
        ),
      ),
    );
  }
}
