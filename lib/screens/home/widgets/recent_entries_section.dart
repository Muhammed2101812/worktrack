import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme.dart';
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
    final c = AppColors.of(context);
    final recent = entries.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Kayıtlar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textMain,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/home/history'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      PhosphorIcons.caretRight(),
                      color: c.primary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 40,
              color: c.textMuted,
            ),
            const SizedBox(height: 8),
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
