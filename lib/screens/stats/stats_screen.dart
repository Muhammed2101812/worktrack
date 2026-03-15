import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Icon(PhosphorIcons.x(), color: MidnightColors.textMain, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Aylık Rapor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: MidnightColors.textMain,
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
                    final entryDate = DateFormat('dd.MM.yyyy').parse(entry.date);
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
                              color: MidnightColors.shimmer1.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIcons.chartPieSlice(),
                              size: 64,
                              color: MidnightColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Bu ay için kayıt bulunamadı.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: MidnightColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return clientsAsync.when(
                    data: (clients) {
                      final Map<String, double> clientHours = {};
                      double totalHours = 0;

                      for (var entry in monthEntries) {
                        clientHours[entry.clientId] = (clientHours[entry.clientId] ?? 0) + entry.durationHours;
                        totalHours += entry.durationHours;
                      }

                      if (totalHours == 0) return const Center(child: Text('Toplam çalışma saati 0.', style: TextStyle(color: MidnightColors.textMain)));

                      final sortedClientIds = clientHours.keys.toList()
                        ..sort((a, b) => clientHours[b]!.compareTo(clientHours[a]!));

                      final colors = [
                        MidnightColors.orange,
                        MidnightColors.primary,
                        MidnightColors.purple,
                      ];

                      return ListView(
                        padding: const EdgeInsets.only(bottom: 100),
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
                                    color: MidnightColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${totalHours.toStringAsFixed(1)} Saat',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: MidnightColors.textMain,
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
                                          sections: sortedClientIds.asMap().entries.map((entry) {
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
                                              titleStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
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
                                          color: MidnightColors.bgColor,
                                          border: Border.all(
                                            color: MidnightColors.cardBorder,
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
                                              style: const TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                color: MidnightColors.textMain,
                                                letterSpacing: -2,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('MMMM', 'tr').format(_selectedMonth).toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 2.0,
                                                color: MidnightColors.textMuted,
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
                                color: MidnightColors.textMuted,
                              ),
                            ),
                          ),
                          ...sortedClientIds.asMap().entries.map((entry) {
                            final index = entry.key;
                            final clientId = entry.value;
                            final hours = clientHours[clientId]!;
                            final client = clients.firstWhere(
                              (c) => c.id == clientId,
                              orElse: () => Client(id: clientId, name: 'Bilinmeyen', color: '#9CA3AF'),
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: MidnightColors.textMain,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: LinearProgressIndicator(
                                            value: hours / totalHours,
                                            backgroundColor: MidnightColors.shimmer1.withValues(alpha: 0.3),
                                            valueColor: AlwaysStoppedAnimation<Color>(color),
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: MidnightColors.textMain,
                                        ),
                                      ),
                                      Text(
                                        '%${percentage.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: MidnightColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: MidnightColors.primary)),
                    error: (e, st) => Center(child: Text('Müşteriler yüklenirken hata oluştu: $e', style: TextStyle(color: MidnightColors.textMain))),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: MidnightColors.primary)),
                error: (e, st) => Center(child: Text('Kayıtlar yüklenirken hata oluştu: $e', style: TextStyle(color: MidnightColors.textMain))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
