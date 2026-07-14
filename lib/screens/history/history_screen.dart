import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/entries_provider.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/dimens.dart';
import '../../core/theme.dart';
import '../history/widgets/month_filter.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? _selectedMonth;
  String _searchQuery = '';
  String _selectedFilter = 'Tümü';
  String _selectedSort = 'Tarih (En Yeni)';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final entriesAsync = ref.watch(entriesProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;

    Widget mainContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              MidnightInput(
                hintText: 'Müşteri veya iş ara...',
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), color: c.primary),
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
            data: (entries) => _buildHistoryList(entries, isWide),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.warningCircle(), size: 64, color: c.error),
                  const SizedBox(height: 16),
                  Text('Hata: $error', style: TextStyle(color: c.textMain)),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (isWide) {
      mainContent = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: mainContent,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'İş Geçmişi',
              onBack: () => context.go('/home/overview'),
              action: _buildSortDropdown(),
            ),
            Expanded(child: mainContent),
          ],
        ),
      ),
      floatingActionButton: isWide
          ? FloatingActionButton(
              onPressed: () => context.push('/home/add'),
              backgroundColor: c.primary,
              child: Icon(Icons.add, color: c.onPrimary),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final c = AppColors.of(context);
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
        margin: const EdgeInsets.only(right: Spacing.s12),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s20, vertical: Spacing.s8),
        decoration: BoxDecoration(
          color: isSelected ? c.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? c.primary.withValues(alpha: 0.4) : c.cardBorder,
            width: 1,
          ),
          borderRadius: Radii.lgBr,
          boxShadow: isSelected ? [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.12),
              blurRadius: 10,
            ),
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? c.primary : c.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List entries, bool isWide) {
    final c = AppColors.of(context);
    List filteredEntries = entries;

    if (_searchQuery.isNotEmpty) {
      filteredEntries = filteredEntries.where((entry) {
        return entry.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               entry.workType.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedMonth != null) {
      filteredEntries = filteredEntries.where((entry) {
        try {
          final entryDate = DateFormat('dd.MM.yyyy').parse(entry.date);
          return entryDate.year == _selectedMonth!.year &&
              entryDate.month == _selectedMonth!.month;
        } catch (_) {
          // Malformed date — exclude entry from the month filter.
          return false;
        }
      }).toList();
    }

    if (filteredEntries.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.history,
          title: 'Henüz kayıt yok',
          subtitle: 'Seçili ay için iş geçmişin burada görünecek.',
        ),
      );
    }

    final isGrouped = _selectedSort.startsWith('Tarih');

    if (isGrouped) {
      final groupedEntries = _groupByDate(filteredEntries);

      return ListView.builder(
        padding: EdgeInsets.only(bottom: isWide ? 40 : 100),
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
                        color: c.cardBorder,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _formatDateHeader(date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: c.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: c.cardBorder,
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
    } else {
      // Sort by duration flat list
      final sortedEntries = List.from(filteredEntries);
      if (_selectedSort == 'Süre (En Uzun)') {
        sortedEntries.sort((a, b) => b.durationHours.compareTo(a.durationHours));
      } else {
        sortedEntries.sort((a, b) => a.durationHours.compareTo(b.durationHours));
      }

      return ListView.builder(
        padding: EdgeInsets.only(bottom: isWide ? 40 : 100),
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          return _buildEntryCard(entry);
        },
      );
    }
  }

  Widget _buildEntryCard(dynamic entry) {
    final c = AppColors.of(context);
    final hasProject =
        entry.projectName != null && entry.projectName.toString().isNotEmpty;
    final clientLabel = hasProject
        ? '${entry.clientName} • ${entry.projectName}'
        : entry.clientName;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      onTap: () => _showEntryDetails(entry),
      child: Row(
        children: [
          AppAvatar(
            name: entry.clientName as String,
            hexColor: entry.clientColor as String,
            size: AvatarSize.md,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.textMain,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.workType} • ${entry.startTime} - ${entry.endTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.durationHours.toStringAsFixed(1)} sa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: c.textMain,
                ),
              ),
              const SizedBox(height: 6),
              if (!entry.synced)
                Icon(
                  PhosphorIcons.cloudArrowUp(),
                  size: 14,
                  color: c.orange,
                )
              else
                Icon(
                  PhosphorIcons.cloudCheck(),
                  size: 14,
                  color: c.emerald,
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

    // Sort keys based on selectedSort
    final sortedKeys = grouped.keys.toList();
    if (_selectedSort == 'Tarih (En Eski)') {
      sortedKeys.sort((a, b) => a.compareTo(b)); // oldest first
    } else {
      sortedKeys.sort((a, b) => b.compareTo(a)); // newest first (default)
    }

    final sortedGrouped = <DateTime, List>{};
    for (final key in sortedKeys) {
      final list = grouped[key]!;
      // Sort entries within the same day by start time
      list.sort((a, b) {
        if (_selectedSort == 'Tarih (En Eski)') {
          return a.startTime.compareTo(b.startTime);
        } else {
          return b.startTime.compareTo(a.startTime);
        }
      });
      sortedGrouped[key] = list;
    }

    return sortedGrouped;
  }

  Widget _buildSortDropdown() {
    final c = AppColors.of(context);
    IconData getSortIcon() {
      switch (_selectedSort) {
        case 'Tarih (En Eski)':
          return PhosphorIcons.sortAscending();
        case 'Süre (En Uzun)':
          return PhosphorIcons.chartLineUp();
        case 'Süre (En Kısa)':
          return PhosphorIcons.chartLineDown();
        case 'Tarih (En Yeni)':
        default:
          return PhosphorIcons.sortDescending();
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: c.navBg, // Popup arka plan rengi
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.shimmer1.withValues(alpha: 0.1),
            border: Border.all(color: c.cardBorder, width: 1),
            borderRadius: Radii.smBr,
          ),
          child: Icon(
            getSortIcon(),
            size: 20,
            color: c.primary,
          ),
        ),
        tooltip: 'Sırala',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.cardBorder, width: 1),
        ),
        offset: const Offset(0, 48),
        onSelected: (String newValue) {
          setState(() {
            _selectedSort = newValue;
          });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _buildPopupItem('Tarih (En Yeni)', 'En Yeni Tarih', PhosphorIcons.sortDescending()),
          _buildPopupItem('Tarih (En Eski)', 'En Eski Tarih', PhosphorIcons.sortAscending()),
          const PopupMenuDivider(height: 1),
          _buildPopupItem('Süre (En Uzun)', 'En Uzun Süre', PhosphorIcons.trendUp()),
          _buildPopupItem('Süre (En Kısa)', 'En Kısa Süre', PhosphorIcons.trendDown()),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String text, IconData icon) {
    final c = AppColors.of(context);
    final isSelected = _selectedSort == value;
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? c.primary : c.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? c.primary : c.textMain,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              PhosphorIcons.check(),
              size: 16,
              color: c.primary,
            ),
        ],
      ),
    );
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final c = AppColors.of(context);
        return AppSheet.decoration(
          context,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kayıt Detayları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.textMain,
                      ),
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.x(), color: c.textMain),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(height: 32, color: c.cardBorder),
                _buildDetailRow(PhosphorIcons.user(), 'Müşteri', entry.clientName),
                if (entry.projectName != null &&
                    entry.projectName.toString().isNotEmpty)
                  _buildDetailRow(
                      PhosphorIcons.folderSimple(), 'Proje', entry.projectName),
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
                      color: c.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.shimmer1.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(entry.notes, style: TextStyle(color: c.textMain)),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        variant: ButtonVariant.ghost,
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/home/add', extra: entry);
                        },
                        child: const Text('Düzenle'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        variant: ButtonVariant.danger,
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: c.navBg,
                              title: Text('Kaydı Sil', style: TextStyle(color: c.textMain)),
                              content: Text('Bu kaydı silmek istediğinize emin misiniz?', style: TextStyle(color: c.textMuted)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('İptal', style: TextStyle(color: c.primary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(foregroundColor: c.error),
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
                        child: const Text('Sil'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: c.textMain))),
        ],
      ),
    );
  }
}
