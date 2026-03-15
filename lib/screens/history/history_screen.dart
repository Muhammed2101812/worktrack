import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/entries_provider.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';
import '../history/widgets/month_filter.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? _selectedMonth = DateTime.now();
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);

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
                    'İş Geçmişi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: MidnightColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  MidnightInput(
                    hintText: 'Müşteri veya iş ara...',
                    prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), color: MidnightColors.primary),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('Tümü', 'Tümü'),
                        _buildFilterChip('Bu Ay', 'Bu Ay'),
                        _buildFilterChip('Geçen Ay', 'Geçen Ay'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  MonthFilter(
                    selectedMonth: _selectedMonth ?? DateTime.now(),
                    onMonthChanged: (month) {
                      setState(() {
                        _selectedMonth = month;
                        _selectedFilter = 'Tümü';
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: entriesAsync.when(
                data: (entries) => _buildHistoryList(entries),
                loading: () => const Center(child: CircularProgressIndicator(color: MidnightColors.primary)),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warningCircle(), size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Hata: $error', style: TextStyle(color: MidnightColors.textMain)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          final now = DateTime.now();
          if (filter == 'Bu Ay') {
            _selectedMonth = DateTime(now.year, now.month);
          } else if (filter == 'Geçen Ay') {
            _selectedMonth = DateTime(now.year, now.month - 1);
          } else {
            _selectedMonth = null;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? MidnightColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? MidnightColors.primary.withValues(alpha: 0.4) : MidnightColors.cardBorder,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: MidnightColors.primary.withValues(alpha: 0.12),
              blurRadius: 10,
            ),
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? MidnightColors.primary : MidnightColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List entries) {
    List filteredEntries = entries;
    
    if (_searchQuery.isNotEmpty) {
      filteredEntries = filteredEntries.where((entry) {
        return entry.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               entry.workType.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedMonth != null) {
      filteredEntries = filteredEntries.where((entry) {
        final entryDate = DateFormat('dd.MM.yyyy').parse(entry.date);
        return entryDate.year == _selectedMonth!.year &&
            entryDate.month == _selectedMonth!.month;
      }).toList();
    }

    if (filteredEntries.isEmpty) {
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
                PhosphorIcons.clockCounterClockwise(),
                size: 64,
                color: MidnightColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz kayıt yok',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: MidnightColors.textMain,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    final groupedEntries = _groupByDate(filteredEntries);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groupedEntries.length,
      itemBuilder: (context, index) {
        final date = groupedEntries.keys.elementAt(index);
        final dayEntries = groupedEntries[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: MidnightColors.cardBorder,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _formatDateHeader(date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: MidnightColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: MidnightColors.cardBorder,
                    ),
                  ),
                ],
              ),
            ),
            ...dayEntries.map((entry) => _buildEntryCard(entry)),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(dynamic entry) {
    final clientColor = Color(int.parse(entry.clientColor.replaceAll('#', '0xFF')));

    return MidnightCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      onTap: () => _showEntryDetails(entry),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: clientColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: clientColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                entry.clientName[0].toUpperCase(),
                style: TextStyle(
                  color: clientColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  entry.workType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MidnightColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.date} • ${entry.startTime} - ${entry.endTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: MidnightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.clientName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: MidnightColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              if (!entry.synced)
                Icon(
                  PhosphorIcons.cloudArrowUp(),
                  size: 14,
                  color: Colors.orange,
                )
              else
                Icon(
                  PhosphorIcons.cloudCheck(),
                  size: 14,
                  color: MidnightColors.emerald,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Map<DateTime, List> _groupByDate(List entries) {
    final grouped = <DateTime, List>{};
    for (final entry in entries) {
      try {
        final parts = entry.date.split('.');
        if (parts.length == 3) {
          final entryDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          final date = DateTime(entryDate.year, entryDate.month, entryDate.day);
          grouped.putIfAbsent(date, () => []).add(entry);
        }
      } catch (e) {
      }
    }
    return grouped;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'BUGÜN';
    } else if (date == yesterday) {
      return 'DÜN';
    } else {
      return DateFormat('d MMMM yyyy', 'tr').format(date).toUpperCase();
    }
  }

  void _showEntryDetails(dynamic entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: MidnightColors.navBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MidnightColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kayıt Detayları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MidnightColors.textMain,
                        ),
                      ),
                      IconButton(
                        icon: Icon(PhosphorIcons.x(), color: MidnightColors.textMain),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: MidnightColors.cardBorder),
                  _buildDetailRow(PhosphorIcons.user(), 'Müşteri', entry.clientName),
                  _buildDetailRow(PhosphorIcons.calendarBlank(), 'Tarih', entry.date),
                  _buildDetailRow(PhosphorIcons.clock(), 'Saat', '${entry.startTime} - ${entry.endTime}'),
                  _buildDetailRow(PhosphorIcons.timer(), 'Süre', '${entry.durationHours.toStringAsFixed(1)} saat'),
                  _buildDetailRow(PhosphorIcons.briefcase(), 'Tür', entry.workType),
                  if (entry.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: MidnightColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MidnightColors.shimmer1.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(entry.notes, style: TextStyle(color: MidnightColors.textMain)),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: MidnightButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/home/add', extra: entry);
                          },
                          child: const Text('Düzenle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MidnightButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: MidnightColors.navBg,
                                title: const Text('Kaydı Sil', style: TextStyle(color: MidnightColors.textMain)),
                                content: const Text('Bu kaydı silmek istediğinize emin misiniz?', style: TextStyle(color: MidnightColors.textMuted)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('İptal', style: TextStyle(color: MidnightColors.primary)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(foregroundColor: MidnightColors.error),
                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              Navigator.pop(context);
                              ref.read(entriesProvider.notifier).deleteEntry(entry.id);
                              CustomToast.show(context, 'Kayıt silindi');
                            }
                          },
                          color: MidnightColors.error.withValues(alpha: 0.1),
                          child: const Text('Sil', style: TextStyle(color: MidnightColors.error, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MidnightColors.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: MidnightColors.textMuted, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: MidnightColors.textMain))),
        ],
      ),
    );
  }
}
