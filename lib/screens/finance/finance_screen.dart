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
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _activeTab = 0; // 0: Müşteri Durumu, 1: Ödemeler Geçmişi

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final clientsAsync = ref.watch(clientsProvider);

    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.transparent, // Let HomeShell handle background
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: entriesAsync.when(
          data: (entries) => paymentsAsync.when(
            data: (payments) => clientsAsync.when(
              data: (clients) => _buildBody(context, entries, payments, clients, isWide),
              loading: () => const Center(child: CircularProgressIndicator(color: MidnightColors.primary)),
              error: (e, _) => Center(child: Text('Müşteriler yüklenemedi: $e', style: const TextStyle(color: MidnightColors.textMain))),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: MidnightColors.primary)),
            error: (e, _) => Center(child: Text('Ödemeler yüklenemedi: $e', style: const TextStyle(color: MidnightColors.textMain))),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: MidnightColors.primary)),
          error: (e, _) => Center(child: Text('İş kayıtları yüklenemedi: $e', style: const TextStyle(color: MidnightColors.textMain))),
        ),
      ),
    );
  }

  double _getEntryPrice(WorkEntry e) {
    if (e.totalPrice > 0.0) return e.totalPrice;
    try {
      final s = e.startTime.split(':');
      final end = e.endTime.split(':');
      final startMin = int.parse(s[0]) * 60 + int.parse(s[1]);
      final endMin = int.parse(end[0]) * 60 + int.parse(end[1]);
      final diff = endMin - startMin;
      final hours = diff > 0 ? diff / 60.0 : 0.0;
      return hours * (e.hourlyRate > 0.0 ? e.hourlyRate : 0.0);
    } catch (_) {
      return 0.0;
    }
  }

  Widget _buildBody(
    BuildContext context,
    List<WorkEntry> entries,
    List<Payment> payments,
    List<Client> clients,
    bool isWide,
  ) {
    // 1. Calculate general stats
    double totalEarned = 0.0;
    for (final e in entries) {
      totalEarned += _getEntryPrice(e);
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
        clientStatsMap[e.clientId]!.earned += _getEntryPrice(e);
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
                      color: MidnightColors.textMain,
                    ),
                  ),
                  MidnightButton(
                    onPressed: () => _showAddPaymentSheet(context, clients),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    borderRadius: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Ödeme Ekle',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
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
                            color: MidnightColors.textMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: remainingBalance > 0
                                ? MidnightColors.orange.withValues(alpha: 0.1)
                                : MidnightColors.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            remainingBalance > 0 ? 'Ödeme Bekliyor' : 'Tümü Tahsil Edildi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: remainingBalance > 0 ? MidnightColors.orange : MidnightColors.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${remainingBalance.toStringAsFixed(1)} TL',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: remainingBalance > 0 ? MidnightColors.orange : MidnightColors.textMain,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: MidnightColors.cardBorder,
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
                                  color: MidnightColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${totalEarned.toStringAsFixed(1)} TL',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MidnightColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: MidnightColors.cardBorder,
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
                                  color: MidnightColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${totalReceived.toStringAsFixed(1)} TL',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MidnightColors.emerald,
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
                  color: MidnightColors.shimmer1,
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
                            color: _activeTab == 0 ? Colors.white : Colors.transparent,
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
                              color: _activeTab == 0 ? MidnightColors.textMain : MidnightColors.textMuted,
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
                            color: _activeTab == 1 ? Colors.white : Colors.transparent,
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
                              color: _activeTab == 1 ? MidnightColors.textMain : MidnightColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: _activeTab == 0
                  ? _buildClientBalances(context, clientFinanceList, isWide)
                  : _buildPaymentsList(context, payments, isWide),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientBalances(BuildContext context, List<_ClientFinance> list, bool isWide) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.users(PhosphorIconsStyle.thin), size: 48, color: MidnightColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Henüz kayıtlı müşteri bulunmuyor.',
              style: TextStyle(color: MidnightColors.textMuted),
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
        final clientColor = Color(int.parse(item.client.color.replaceAll('#', '0xFF')));

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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: MidnightColors.textMain,
                      ),
                    ),
                  ),
                  Text(
                    item.balance > 0
                        ? '${item.balance.toStringAsFixed(1)} TL Borç'
                        : 'Ödendi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: item.balance > 0 ? MidnightColors.orange : MidnightColors.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: MidnightColors.cardBorder),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hakediş: ${item.earned.toStringAsFixed(1)} TL',
                    style: TextStyle(fontSize: 12, color: MidnightColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Alınan: ${item.received.toStringAsFixed(1)} TL',
                    style: TextStyle(fontSize: 12, color: MidnightColors.emerald, fontWeight: FontWeight.w600),
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
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.receipt(PhosphorIconsStyle.thin), size: 48, color: MidnightColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Henüz ödeme kaydı eklenmemiş.',
              style: TextStyle(color: MidnightColors.textMuted),
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
        final color = Color(int.parse(payment.clientColor.replaceAll('#', '0xFF')));

        return Dismissible(
          key: Key(payment.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: MidnightColors.error,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: MidnightColors.textMain),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            payment.date,
                            style: TextStyle(fontSize: 11, color: MidnightColors.textMuted),
                          ),
                          if (payment.notes.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: BoxDecoration(color: MidnightColors.textMuted, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                payment.notes,
                                style: TextStyle(fontSize: 11, color: MidnightColors.textMuted, overflow: TextOverflow.ellipsis),
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
                      '+${payment.amount.toStringAsFixed(1)} TL',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: MidnightColors.emerald, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      payment.synced ? PhosphorIcons.cloudCheck(PhosphorIconsStyle.fill) : PhosphorIcons.cloudArrowUp(),
                      size: 16,
                      color: payment.synced ? MidnightColors.emerald : MidnightColors.textMuted,
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
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightColors.navBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: MidnightColors.cardBorder, width: 1),
        ),
        title: const Text('Ödeme Kaydını Sil', style: TextStyle(color: MidnightColors.textMain)),
        content: Text('${payment.clientName} müşterisinden alınan ${payment.amount} TL tutarındaki ödeme kaydı silinsin mi?', style: const TextStyle(color: MidnightColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç', style: TextStyle(color: MidnightColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              ref.read(paymentsProvider.notifier).deletePayment(payment.id);
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: MidnightColors.error),
            child: const Text('Sil', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPaymentSheet(BuildContext context, List<Client> clients) async {
    if (clients.isEmpty) {
      CustomToast.show(context, 'Lütfen önce Ayarlar sayfasından bir müşteri oluşturun.');
      return;
    }

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
          return Container(
            decoration: BoxDecoration(
              color: MidnightColors.navBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: MidnightColors.cardBorder, width: 1),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MidnightColors.textMain),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      icon: Icon(PhosphorIcons.x(), color: MidnightColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Client Dropdown
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('MÜŞTERİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: MidnightColors.textMuted)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<Client>(
                      value: selectedClient,
                      dropdownColor: MidnightColors.navBg,
                      icon: Icon(PhosphorIcons.caretDown(), color: MidnightColors.textMuted),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                      items: clients.map((c) {
                        final color = Color(int.parse(c.color.replaceAll('#', '0xFF')));
                        return DropdownMenuItem<Client>(
                          value: c,
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Text(c.name, style: const TextStyle(fontSize: 14, color: MidnightColors.textMain, fontWeight: FontWeight.w500)),
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
                  child: Text('TUTAR (TL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: MidnightColors.textMuted)),
                ),
                MidnightInput(
                  controller: amountController,
                  hintText: 'Örn: 2500',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icon(PhosphorIcons.currencyCircleDollar(), color: MidnightColors.primary),
                ),
                const SizedBox(height: 20),

                // Date Picker Button
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('TARİH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: MidnightColors.textMuted)),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: MidnightColors.primary,
                              onPrimary: Colors.white,
                              onSurface: MidnightColors.textMain,
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
                        Icon(PhosphorIcons.calendar(), color: MidnightColors.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd.MM.yyyy').format(selectedDate),
                          style: const TextStyle(color: MidnightColors.textMain, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Icon(PhosphorIcons.caretRight(), color: MidnightColors.textMuted, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Notes Input
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('NOT (İSTEĞE BAĞLI)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: MidnightColors.textMuted)),
                ),
                MidnightInput(
                  controller: noteController,
                  hintText: 'Örn: İlk peşinat / Banka havalesi',
                  prefixIcon: Icon(PhosphorIcons.note(), color: MidnightColors.primary),
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
                    await ref.read(paymentsProvider.notifier).addPayment(payment);
                    if (context.mounted) {
                      CustomToast.show(context, 'Ödeme kaydı başarıyla eklendi');
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.checkCircle(), color: Colors.white),
                      const SizedBox(width: 10),
                      const Text(
                        'KAYDET',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
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
