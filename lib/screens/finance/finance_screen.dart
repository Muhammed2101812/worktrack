import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/payment.dart';
import '../../models/client.dart';
import '../../models/work_entry.dart';
import '../../providers/payments_provider.dart';
import '../../providers/entries_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';

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

  /// Parses a `#RRGGBB` / `0xFFRRGGBB` colour string into a [Color], falling
  /// back to [fallback] if the value is malformed.
  Color _parseColor(String hex, Color fallback) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
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
    final c = AppColors.of(context);
    final currency = ref.watch(currencyProvider).valueOrNull ?? 'TL';

    // 1. Calculate general stats
    double totalEarned = 0.0;
    for (final e in entries) {
      totalEarned += e.effectivePrice;
    }

    double totalReceived = 0.0;
    for (final p in payments) {
      totalReceived += p.amount;
    }

    final double remainingBalance = totalEarned - totalReceived;

    // 2. Calculate balance per client
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
            // Page Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Finansal Durum',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: c.textMain,
                    ),
                  ),
                  MidnightButton(
                    onPressed: () => _showAddPaymentSheet(context, clients),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    borderRadius: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: c.onPrimary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Ödeme Ekle',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: c.onPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Financial Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: MidnightCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kalan Alacak',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: remainingBalance > 0
                                ? c.orange.withValues(alpha: 0.1)
                                : c.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
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
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: remainingBalance > 0 ? c.orange : c.textMain,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: c.cardBorder,
                    ),
                    const SizedBox(height: 16),
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
                        const SizedBox(width: 24),
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
              ),
            ),

            // Tab bar selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.shimmer1,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? c.cardBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Müşteri Durumu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w600,
                              color: _activeTab == 0 ? c.textMain : c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? c.cardBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Ödemeler Geçmişi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w600,
                              color: _activeTab == 1 ? c.textMain : c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
        final clientColor = _parseColor(item.client.color, c.primary);

        return MidnightCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: clientColor,
                      shape: BoxShape.circle,
                    ),
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
        final color = _parseColor(payment.clientColor, c.primary);

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
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) => _showDeletePaymentConfirmDialog(context, payment),
          child: MidnightCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          backgroundColor: c.navBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: c.cardBorder, width: 1),
          ),
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
          return Container(
            decoration: BoxDecoration(
              color: sc.navBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: sc.cardBorder, width: 1),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ödeme Alındı Ekle',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sc.textMain),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      icon: Icon(PhosphorIcons.x(), color: sc.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Client Dropdown
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('MÜŞTERİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc.textMuted)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: sc.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sc.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<Client>(
                      initialValue: selectedClient,
                      dropdownColor: sc.navBg,
                      icon: Icon(PhosphorIcons.caretDown(), color: sc.textMuted),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                      items: clients.map((client) {
                        final color = _parseColor(client.color, sc.primary);
                        return DropdownMenuItem<Client>(
                          value: client,
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Text(client.name, style: TextStyle(fontSize: 14, color: sc.textMain, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedClient = val;
                        });
                      },
                    ),
                  ),
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
                  child: MidnightCard(
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
