import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/pdf_export_service.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../providers/entries_provider.dart';
import '../../providers/clients_provider.dart';
import '../../models/client.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';
import '../history/widgets/month_filter.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  DateTime _selectedMonth = DateTime.now();
  // 0 = Saatler, 1 = Gelir
  int _selectedView = 0;

  DateTime? _tryParseDate(String s) {
    try {
      return DateFormat('dd.MM.yyyy').parse(s);
    } catch (_) {
      return null;
    }
  }

  /// Seçili ayın gün sayısı (28-31).
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final entriesAsync = ref.watch(entriesProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aylık Rapor',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: c.textMain,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final entriesVal = ref.read(entriesProvider).valueOrNull;
                          final clientsVal = ref.read(clientsProvider).valueOrNull;
                          if (entriesVal == null || clientsVal == null) {
                            if (context.mounted) {
                              CustomToast.show(context, 'Veriler henüz hazır değil');
                            }
                            return;
                          }
                          try {
                            final name = await PdfExportService.exportMonthlyReport(
                              entries: entriesVal,
                              clients: clientsVal,
                              month: _selectedMonth,
                            );
                            if (context.mounted) {
                              CustomToast.show(context, '$name.pdf indiriliyor');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              CustomToast.show(context, 'PDF oluşturulurken hata: $e');
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.filePdf(), color: c.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'PDF İndir',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: c.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                MonthFilter(
                  selectedMonth: _selectedMonth,
                  onMonthChanged: (month) {
                    setState(() {
                      _selectedMonth = month;
                    });
                  },
                ),
                Expanded(
                  child: entriesAsync.when(
                    data: (entries) {
                      final monthEntries = entries.where((entry) {
                        final entryDate = _tryParseDate(entry.date);
                        if (entryDate == null) return false;
                        return entryDate.year == _selectedMonth.year &&
                            entryDate.month == _selectedMonth.month;
                      }).toList();

                      if (monthEntries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: c.shimmer1.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIcons.chartPieSlice(),
                                  size: 64,
                                  color: c.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Bu ay için kayıt bulunamadı.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: c.textMain,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return clientsAsync.when(
                        data: (clients) => Column(
                          children: [
                            // ── Segment seçici (Saatler / Gelir) ──
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
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
                                        onTap: () => setState(
                                            () => _selectedView = 0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _selectedView == 0
                                                ? c.cardBg
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: _selectedView == 0
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.05),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Saatler',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  _selectedView == 0
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                              color: _selectedView == 0
                                                  ? c.textMain
                                                  : c.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _selectedView = 1),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _selectedView == 1
                                                ? c.cardBg
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: _selectedView == 1
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.05),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Gelir',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  _selectedView == 1
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                              color: _selectedView == 1
                                                  ? c.textMain
                                                  : c.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _selectedView == 0
                                  ? _buildHoursView(
                                      c, clients, monthEntries, isWide)
                                  : _buildEarningsView(
                                      c, clients, monthEntries, isWide),
                            ),
                          ],
                        ),
                        loading: () => Center(
                            child: CircularProgressIndicator(color: c.primary)),
                        error: (e, st) => Center(
                            child: Text(
                                'Müşteriler yüklenirken hata oluştu: $e',
                                style: TextStyle(color: c.textMain))),
                      );
                    },
                    loading: () => Center(
                        child: CircularProgressIndicator(color: c.primary)),
                    error: (e, st) => Center(
                        child: Text('Kayıtlar yüklenirken hata oluştu: $e',
                            style: TextStyle(color: c.textMain))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SAATLER GÖRÜNÜMÜ (mevcut görünüm — korunmuş)
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildHoursView(AppPalette c, List<Client> clients,
      List monthEntries, bool isWide) {
    final Map<String, double> clientHours = {};
    double totalHours = 0;

    for (var entry in monthEntries) {
      clientHours[entry.clientId] =
          (clientHours[entry.clientId] ?? 0) + entry.durationHours;
      totalHours += entry.durationHours;
    }

    // Proje bazlı süre hesaplama
    final Map<String, double> projectHours = {};
    final Map<String, String> projectNames = {};
    double projectTotalHours = 0;
    for (var entry in monthEntries) {
      final pId = entry.projectId;
      final pName = entry.projectName;
      if (pId != null &&
          pId.isNotEmpty &&
          pName != null &&
          pName.isNotEmpty) {
        projectHours[pId] =
            (projectHours[pId] ?? 0) + entry.durationHours;
        projectNames[pId] = pName;
        projectTotalHours += entry.durationHours;
      }
    }
    final sortedProjectIds = projectHours.keys.toList()
      ..sort((a, b) => projectHours[b]!.compareTo(projectHours[a]!));

    if (totalHours == 0)
      return Center(
          child: Text('Toplam çalışma saati 0.',
              style: TextStyle(color: c.textMain)));

    final sortedClientIds = clientHours.keys.toList()
      ..sort((a, b) => clientHours[b]!.compareTo(clientHours[a]!));

    final colors = [
      c.orange,
      c.primary,
      c.purple,
    ];

    return ListView(
      padding: EdgeInsets.only(bottom: isWide ? 40 : 100),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'TOPLAM ÇALIŞMA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${totalHours.toStringAsFixed(1)} Saat',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: c.textMain,
                ),
              ),
              const SizedBox(height: 32),
              Stack(
                children: [
                  SizedBox(
                    width: 256,
                    height: 256,
                    child: PieChart(
                      PieChartData(
                        sections: sortedClientIds
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final clientId = entry.value;
                          final hours = clientHours[clientId]!;
                          final color = colors[index % colors.length];
                          final percentage = (hours / totalHours) * 100;

                          return PieChartSectionData(
                            color: color,
                            value: hours,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: c.onPrimary,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 4,
                        centerSpaceRadius: 96,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.bgColor,
                        border: Border.all(
                          color: c.cardBorder,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${totalHours.toInt()}s',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: c.textMain,
                              letterSpacing: -2,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM', 'tr')
                                .format(_selectedMonth)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'MÜŞTERİ BAZLI DAĞILIM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: c.textMuted,
            ),
          ),
        ),
        ...sortedClientIds.asMap().entries.map((entry) {
          final index = entry.key;
          final clientId = entry.value;
          final hours = clientHours[clientId]!;
          final client = clients.firstWhere(
            (cl) => cl.id == clientId,
            orElse: () => Client(
                id: clientId, name: 'Bilinmeyen', color: '#9CA3AF'),
          );
          final percentage = (hours / totalHours) * 100;
          final color = colors[index % colors.length];

          return MidnightCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      client.name[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: c.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: hours / totalHours,
                          backgroundColor:
                              c.shimmer1.withValues(alpha: 0.3),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${hours.toStringAsFixed(1)} Sa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.textMain,
                      ),
                    ),
                    Text(
                      '%${percentage.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        // ── PROJE BAZLI DAĞILIM ──
        if (sortedProjectIds.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'PROJE BAZLI DAĞILIM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: c.textMuted,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sortedProjectIds
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final pId = entry.value;
                    final hours = projectHours[pId]!;
                    final color = colors[index % colors.length];
                    final percentage =
                        (hours / projectTotalHours) * 100;
                    return PieChartSectionData(
                      color: color,
                      value: hours,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 45,
                      titleStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: c.onPrimary,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 45,
                ),
              ),
            ),
          ),
          ...sortedProjectIds.asMap().entries.map((entry) {
            final index = entry.key;
            final pId = entry.value;
            final hours = projectHours[pId]!;
            final name = projectNames[pId]!;
            final percentage = (hours / projectTotalHours) * 100;
            final color = colors[index % colors.length];
            return MidnightCard(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                          PhosphorIcons.folderSimple(),
                          color: color,
                          size: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: c.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: hours / projectTotalHours,
                            backgroundColor:
                                c.shimmer1.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                color),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${hours.toStringAsFixed(1)} Sa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: c.textMain,
                        ),
                      ),
                      Text(
                        '%${percentage.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // GELİR GÖRÜNÜMÜ (yeni)
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildEarningsView(AppPalette c, List<Client> clients,
      List monthEntries, bool isWide) {
    // Müşteri bazlı saat + gelir hesapla
    final Map<String, double> clientHours = {};
    final Map<String, double> clientEarnings = {};
    double totalEarnings = 0;

    for (var entry in monthEntries) {
      final price = entry.effectivePrice;
      clientHours[entry.clientId] =
          (clientHours[entry.clientId] ?? 0) + entry.durationHours;
      clientEarnings[entry.clientId] =
          (clientEarnings[entry.clientId] ?? 0) + price;
      totalEarnings += price;
    }

    final colors = [c.orange, c.primary, c.purple];

    // Gelir yoksa (tüm entries için effectivePrice 0)
    if (totalEarnings == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: c.shimmer1.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.currencyCircleDollar(),
                  size: 64,
                  color: c.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bu ay için gelir kaydı yok.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: c.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sabit fiyat veya saatlik ücret tanımlanmış kayıt bulunamadı.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedClientIds = clientEarnings.keys.toList()
      ..sort((a, b) => clientEarnings[b]!.compareTo(clientEarnings[a]!));

    // ── Günlük gelir hesabı (LineChart için) ──
    final int daysCount = _daysInMonth(_selectedMonth.year, _selectedMonth.month);
    final List<double> dailyEarnings =
        List<double>.filled(daysCount, 0.0, growable: false);
    for (var entry in monthEntries) {
      final d = _tryParseDate(entry.date);
      if (d == null) continue;
      final day = d.day; // 1-based
      if (day >= 1 && day <= daysCount) {
        dailyEarnings[day - 1] += entry.effectivePrice;
      }
    }
    final bool hasDailyData =
        dailyEarnings.any((v) => v > 0);

    return ListView(
      padding: EdgeInsets.only(bottom: isWide ? 40 : 100),
      children: [
        // ── TOPLAM GELİR ──
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'TOPLAM GELİR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${totalEarnings.toStringAsFixed(0)} TL',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: c.textMain,
                ),
              ),
              const SizedBox(height: 32),
              Stack(
                children: [
                  SizedBox(
                    width: 256,
                    height: 256,
                    child: PieChart(
                      PieChartData(
                        sections: sortedClientIds
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final clientId = entry.value;
                          final earning = clientEarnings[clientId]!;
                          final color = colors[index % colors.length];
                          final percentage =
                              (earning / totalEarnings) * 100;

                          return PieChartSectionData(
                            color: color,
                            value: earning,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: c.onPrimary,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 4,
                        centerSpaceRadius: 96,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.bgColor,
                        border: Border.all(
                          color: c.cardBorder,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${totalEarnings.toStringAsFixed(0)} TL',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: c.textMain,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM', 'tr')
                                .format(_selectedMonth)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ── MÜŞTERİ BAZLI GELİR DAĞILIMI ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'MÜŞTERİ BAZLI DAĞILIM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: c.textMuted,
            ),
          ),
        ),
        ...sortedClientIds.asMap().entries.map((entry) {
          final index = entry.key;
          final clientId = entry.value;
          final earning = clientEarnings[clientId]!;
          final hours = clientHours[clientId] ?? 0;
          final avgRate = hours > 0 ? earning / hours : 0.0;
          final client = clients.firstWhere(
            (cl) => cl.id == clientId,
            orElse: () => Client(
                id: clientId, name: 'Bilinmeyen', color: '#9CA3AF'),
          );
          final percentage = (earning / totalEarnings) * 100;
          final color = colors[index % colors.length];

          return MidnightCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      client.name[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: c.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: earning / totalEarnings,
                          backgroundColor:
                              c.shimmer1.withValues(alpha: 0.3),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${hours.toStringAsFixed(1)} sa',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ort. ${avgRate.toStringAsFixed(0)} TL/sa',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${earning.toStringAsFixed(0)} TL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.textMain,
                      ),
                    ),
                    Text(
                      '%${percentage.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        // ── GÜNLÜK GELİR (LineChart) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'GÜNLÜK GELİR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: c.textMuted,
            ),
          ),
        ),
        if (hasDailyData)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MidnightCard(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      // X ekseni: 0 = gün 1, daysCount-1 = son gün.
                      // Her günü doğrudan göstermek yerine biraz nefes
                      // alması için minX/maxX'i gün aralığına ayarlıyoruz.
                      minX: 0,
                      maxX: (daysCount - 1).toDouble(),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) {
                            return spots.map((s) {
                              return LineTooltipItem(
                                'Gün ${(s.x + 1).toInt()}\n${s.y.toStringAsFixed(0)} TL',
                                TextStyle(
                                  color: c.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Gün',
                            style:
                                TextStyle(fontSize: 10, color: c.textMuted),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (daysCount > 16)
                                ? 5
                                : (daysCount > 8 ? 2 : 1),
                            getTitlesWidget: (value, meta) {
                              final day = (value + 1).toInt();
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 6),
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                      fontSize: 10, color: c.textMuted),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.min) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 6),
                                child: Text(
                                  '${value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontSize: 10, color: c.textMuted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: c.shimmer1.withValues(alpha: 0.6),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < daysCount; i++)
                              FlSpot(i.toDouble(), dailyEarnings[i]),
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: c.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: c.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: MidnightCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    PhosphorIcons.chartLineUp(),
                    size: 40,
                    color: c.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bu ay için günlük gelir kaydı yok.',
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
