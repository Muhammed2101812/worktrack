import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme.dart';
import '../../../providers/entries_provider.dart';

class TodaySummaryCard extends ConsumerStatefulWidget {
  const TodaySummaryCard({super.key});

  @override
  ConsumerState<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends ConsumerState<TodaySummaryCard> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final dateStr = DateFormat('dd.MM.yyyy').format(_selectedDate);

    return entriesAsync.when(
      data: (allEntries) {
        final entries =
            allEntries.where((e) => e.date == dateStr).toList();
        final totalHours =
            entries.fold<double>(0, (sum, e) => sum + e.durationHours);
        final hours = totalHours.toInt();
        final minutes = ((totalHours - hours) * 60).round();
        final hasUnsynced = entries.any((e) => !e.synced);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isToday
                        ? 'Bugün'
                        : DateFormat('d MMM', 'tr').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Icon(
                      PhosphorIcons.calendarBlank(),
                      color: isToday
                          ? AppColors.textMuted
                          : AppColors.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$hours',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      color: AppColors.primary,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'sa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$minutes',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      color: AppColors.primary,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'dk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasUnsynced
                          ? Colors.orange.withValues(alpha: 0.1)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasUnsynced
                              ? Icons.cloud_upload_outlined
                              : Icons.check_circle_rounded,
                          color: hasUnsynced
                              ? Colors.orange
                              : AppColors.primary,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasUnsynced ? 'Bekliyor' : 'Senkronize',
                          style: TextStyle(
                            color: hasUnsynced
                                ? Colors.orange
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${entries.length} Çalışma',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
      error: (_, __) => const SizedBox(),
    );
  }
}
