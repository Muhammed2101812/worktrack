import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../models/payment.dart';
import '../add_entry/widgets/client_dropdown.dart';
import '../../models/client.dart';
import '../../models/work_entry.dart';
import '../../providers/payments_provider.dart';
import '../../providers/entries_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';
import '../home/widgets/finance_summary_card.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _activeTab = 0; // 0: Müşteri Durumu, 1: Ödemeler Geçmişi
  final _paymentSearchController = TextEditingController();
  String _paymentSearchQuery = '';

  @override
  void dispose() {
    _paymentSearchController.dispose();
    super.dispose();
  }

  /// Filters payments by the current search query (client name or notes).
  List<Payment> _filterPayments(List<Payment> payments) {
    if (_paymentSearchQuery.isEmpty) return payments;
    final q = _paymentSearchQuery.toLowerCase();
    return payments
        .where((p) =>
            p.clientName.toLowerCase().contains(q) ||
            p.notes.toLowerCase().contains(q) ||
            p.date.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final entriesAsync = ref.watch(entriesProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final clientsAsync = ref.watch(clientsProvider);
    // Watch currency to trigger rebuild when it changes
    ref.watch(currencyProvider);

    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.transparent, // Let HomeShell handle background
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: entriesAsync.when(
          data: (entries) => paymentsAsync.when(
            data: (payments) => clientsAsync.when(
              data: (clients) => _buildBody(context, entries, payments, clients, isWide),
              loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
              error: (e, _) => Center(child: Text('Müşteriler yüklenemedi: $e', style: TextStyle(color: c.textMain))),
            ),
            loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
            error: (e, _) => Center(child: Text('Ödemeler yüklenemedi: $e', style: TextStyle(color: c.textMain))),
          ),
          loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(child: Text('İş kayıtları yüklenemedi: $e', style: TextStyle(color: c.textMain))),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<WorkEntry> entries,
    List<Payment> payments,
    List<Client> clients,
    bool isWide,
  ) {
    final currency = ref.watch(currencyProvider).valueOrNull ?? 'TL';

    // 1. Calculate balance per client
    final clientStatsMap = <String, _ClientFinance>{};
    for (final c in clients) {
      clientStatsMap[c.id] = _ClientFinance(client: c);
    }

    for (final e in entries) {
      if (clientStatsMap.containsKey(e.clientId)) {
        clientStatsMap[e.clientId]!.earned += e.effectivePrice;
      }
    }

    for (final p in payments) {
      if (clientStatsMap.containsKey(p.clientId)) {
        clientStatsMap[p.clientId]!.received += p.amount;
      }
    }

    final clientFinanceList = clientStatsMap.values.toList()
      ..sort((a, b) => b.balance.compareTo(a.balance)); // Sort by highest remaining balance

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Page Header with back button
            ScreenHeader(
              title: 'Finansal Durum',
              onBack: () => context.go('/home/overview'),
              action: AppButton(
                onPressed: () => _showAddPaymentSheet(context, clients),
                variant: ButtonVariant.solid,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
                    const SizedBox(width: 6),
                    const Text('Ödeme Ekle', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),

            // Financial Summary Card (reused widget)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: FinanceSummaryCard(
                entries: entries,
                payments: payments,
                currency: currency,
              ),
            ),

            // Tab bar selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SegmentedControl(
                selected: _activeTab,
                onChanged: (i) => setState(() => _activeTab = i),
                labels: const ['Müşteri Durumu', 'Ödemeler Geçmişi'],
              ),
            ),

            // Search bar (only on payments history tab)
            if (_activeTab == 1 && payments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: MidnightInput(
                  controller: _paymentSearchController,
                  hintText: 'Ödemelerde ara (müşteri, not)...',
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                      color: AppColors.of(context).textMuted, size: 18),
                  suffixIcon: _paymentSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _paymentSearchController.clear();
                            setState(() => _paymentSearchQuery = '');
                          },
                        )
                      : null,
                  onChanged: (value) => setState(() => _paymentSearchQuery = value),
                ),
              ),

            // Tab Content
            Expanded(
              child: _activeTab == 0
                  ? _buildClientBalances(context, clientFinanceList, isWide)
                  : _buildPaymentsList(context, _filterPayments(payments), isWide),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientBalances(BuildContext context, List<_ClientFinance> list, bool isWide) {
    final c = AppColors.of(context);
    final currency = ref.watch(currencyProvider).valueOrNull ?? 'TL';

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.users(PhosphorIconsStyle.thin), size: 48, color: c.textMuted),
            const SizedBox(height: 12),
            Text(
              'Henüz kayıtlı müşteri bulunmuyor.',
              style: TextStyle(color: c.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(24, 8, 24, isWide ? 40 : 120),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];

        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(
                    name: item.client.name,
                    hexColor: item.client.color,
                    dot: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.client.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: c.textMain,
                      ),
                    ),
                  ),
                  Text(
                    item.balance > 0
                        ? '${item.balance.toStringAsFixed(1)} $currency Borç'
                        : 'Ödendi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: item.balance > 0 ? c.orange : c.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: c.cardBorder),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hakediş: ${item.earned.toStringAsFixed(1)} $currency',
                    style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Alınan: ${item.received.toStringAsFixed(1)} $currency',
                    style: TextStyle(fontSize: 12, color: c.emerald, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsList(BuildContext context, List<Payment> list, bool isWide) {
    final c = AppColors.of(context);
    final currency = ref.watch(currencyProvider).valueOrNull ?? 'TL';

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.receipt(PhosphorIconsStyle.thin), size: 48, color: c.textMuted),
            const SizedBox(height: 12),
            Text(
              'Henüz ödeme kaydı eklenmemiş.',
              style: TextStyle(color: c.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(24, 8, 24, isWide ? 40 : 120),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final payment = list[index];

        return Dismissible(
          key: Key(payment.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: c.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.delete_outline,
                color: Theme.of(context).extension<AppPalette>()!.onPrimary, size: 28),
          ),
          confirmDismiss: (direction) => _showDeletePaymentConfirmDialog(context, payment),
          child: AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AppAvatar(
                  name: payment.clientName,
                  hexColor: payment.clientColor,
                  dot: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.clientName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: c.textMain),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            payment.date,
                            style: TextStyle(fontSize: 11, color: c.textMuted),
                          ),
                          if (payment.notes.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: BoxDecoration(color: c.textMuted, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                payment.notes,
                                style: TextStyle(fontSize: 11, color: c.textMuted, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '+${payment.amount.toStringAsFixed(1)} $currency',
                      style: TextStyle(fontWeight: FontWeight.bold, color: c.emerald, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      payment.synced ? PhosphorIcons.cloudCheck(PhosphorIconsStyle.fill) : PhosphorIcons.cloudArrowUp(),
                      size: 16,
                      color: payment.synced ? c.emerald : c.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeletePaymentConfirmDialog(BuildContext context, Payment payment) {
    final currency = ref.read(currencyProvider).valueOrNull ?? 'TL';
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: AppDialog.background(context),
          shape: AppDialog.shape(context),
          title: Text('Ödeme Kaydını Sil', style: TextStyle(color: c.textMain)),
          content: Text('${payment.clientName} müşterisinden alınan ${payment.amount} $currency tutarındaki ödeme kaydı silinsin mi?', style: TextStyle(color: c.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Vazgeç', style: TextStyle(color: c.textMuted)),
            ),
            TextButton(
              onPressed: () {
                ref.read(paymentsProvider.notifier).deletePayment(payment.id);
                Navigator.pop(ctx, true);
              },
              style: TextButton.styleFrom(foregroundColor: c.error),
              child: const Text('Sil', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPaymentSheet(BuildContext context, List<Client> clients) async {
    if (clients.isEmpty) {
      CustomToast.show(context, 'Lütfen önce Ayarlar sayfasından bir müşteri oluşturun.');
      return;
    }

    final currency = ref.read(currencyProvider).valueOrNull ?? 'TL';
    Client? selectedClient = clients.first;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (dialogCtx, setSheetState) {
          final sc = AppColors.of(dialogCtx);
          return AppSheet.decoration(
            dialogCtx,
            title: 'Ödeme Ekle',
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: Icon(PhosphorIcons.x(), color: sc.textMuted),
                      ),
                    ],
                  ),

                  // Client Dropdown
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('MÜŞTERİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc.textMuted)),
                  ),
                  ClientDropdown(
                    clients: clients,
                    selectedClient: selectedClient,
                    onClientSelected: (client) {
                      setSheetState(() {
                        selectedClient = client;
                      });
                    },
                    onAddClient: () {
                      Navigator.pop(dialogCtx);
                      context.go('/settings');
                      CustomToast.show(context, 'Yeni müşteri eklemek için Ayarlar sayfasını kullanın.');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Amount Input
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('TUTAR ($currency)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc.textMuted)),
                  ),
                  MidnightInput(
                    controller: amountController,
                    hintText: 'Örn: 2500',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icon(PhosphorIcons.currencyCircleDollar(), color: sc.primary),
                  ),
                  const SizedBox(height: 20),

                  // Date Picker Button
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('TARİH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc.textMuted)),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogCtx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (dpCtx, child) {
                          final dpc = AppColors.of(dpCtx);
                          return Theme(
                            data: Theme.of(dpCtx).copyWith(
                              colorScheme: ColorScheme.fromSeed(
                                seedColor: dpc.primary,
                                brightness: Theme.of(dpCtx).brightness,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setSheetState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.calendar(), color: sc.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd.MM.yyyy').format(selectedDate),
                            style: TextStyle(color: sc.textMain, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Icon(PhosphorIcons.caretRight(), color: sc.textMuted, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes Input
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('NOT (İSTEĞE BAĞLI)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc.textMuted)),
                  ),
                  MidnightInput(
                    controller: noteController,
                    hintText: 'Örn: İlk peşinat / Banka havalesi',
                    prefixIcon: Icon(PhosphorIcons.note(), color: sc.primary),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  MidnightButton(
                    onPressed: () async {
                      final amountText = amountController.text.trim().replaceAll(',', '.');
                      final amountVal = double.tryParse(amountText) ?? 0.0;
                      if (amountVal <= 0) {
                        CustomToast.show(dialogCtx, 'Lütfen geçerli bir tutar girin');
                        return;
                      }

                      if (selectedClient == null) {
                        CustomToast.show(dialogCtx, 'Müşteri seçilmelidir');
                        return;
                      }

                      final payment = Payment(
                        clientId: selectedClient!.id,
                        clientName: selectedClient!.name,
                        clientColor: selectedClient!.color,
                        amount: amountVal,
                        date: DateFormat('dd.MM.yyyy').format(selectedDate),
                        notes: noteController.text.trim(),
                      );

                      Navigator.pop(dialogCtx);
                      try {
                        await ref.read(paymentsProvider.notifier).addPayment(payment);
                        if (context.mounted) {
                          CustomToast.show(context, 'Ödeme kaydı başarıyla eklendi');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          CustomToast.show(context, 'Ödeme kaydedilemedi, lütfen tekrar deneyin');
                        }
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.checkCircle(), color: sc.onPrimary),
                        const SizedBox(width: 10),
                        Text(
                          'KAYDET',
                          style: TextStyle(fontWeight: FontWeight.bold, color: sc.onPrimary, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    amountController.dispose();
    noteController.dispose();
  }
}

class _ClientFinance {
  final Client client;
  double earned = 0.0;
  double received = 0.0;

  _ClientFinance({required this.client});

  double get balance => earned - received;
}
