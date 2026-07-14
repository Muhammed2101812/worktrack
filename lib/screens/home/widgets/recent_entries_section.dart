import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dimens.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/work_entry.dart';
import 'entry_list_tile.dart';

/// "Son Kayıtlar" section reused by the Overview screen. Shows a header with a
/// "Tümünü Gör" link (navigates to the full History screen) followed by up to
/// [limit] recent entries.
class RecentEntriesSection extends StatelessWidget {
  final List<WorkEntry> entries;
  final int limit;
  final bool emptyState;

  const RecentEntriesSection({
    super.key,
    required this.entries,
    this.limit = 5,
    this.emptyState = false,
  });

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: SectionHeader(
            title: 'Son Kayıtlar',
            actionLabel: 'Tümünü Gör',
            onAction: () => context.push('/home/history'),
          ),
        ),
        const SizedBox(height: Spacing.s8),
        if (recent.isEmpty && emptyState)
          _buildEmptyState(context)
        else
          ...recent.map((entry) => EntryListTile(entry: entry)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 40,
              color: c.textMuted,
            ),
            const SizedBox(height: Spacing.s8),
            Text(
              'Henüz kayıt yok',
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
