import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/dimens.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
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
    final c = AppColors.of(context);
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

        return AppCard(
          variant: CardVariant.hero,
          padding: const EdgeInsets.all(Spacing.s24),
          ledgerLine: true,
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: c.textMuted,
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
                            colorScheme: ColorScheme.fromSeed(
                              seedColor: c.primary,
                              brightness: Theme.of(ctx).brightness,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        borderRadius: Radii.xsBr,
                        border: Border.all(
                          color: c.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.calendarBlank(),
                            color: c.primary,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isToday ? 'Tarih Seç' : 'Değiştir',
                            style: TextStyle(
                              fontSize: 12,
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
              const SizedBox(height: Spacing.s16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$hours',
                    style: AppTexts.figureLg(context).copyWith(
                      color: c.primary,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'sa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$minutes',
                    style: AppTexts.figureLg(context).copyWith(
                      color: c.primary,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'dk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.s20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasUnsynced
                          ? c.orange.withValues(alpha: 0.1)
                          : c.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.xs),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasUnsynced
                              ? Icons.cloud_upload_outlined
                              : Icons.check_circle_rounded,
                          color: hasUnsynced ? c.orange : c.primary,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasUnsynced ? 'Bekliyor' : 'Senkronize',
                          style: TextStyle(
                            color: hasUnsynced ? c.orange : c.primary,
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
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: c.primary,
          ),
        ),
      ),
      error: (_, __) => const SizedBox(),
    );
  }
}
