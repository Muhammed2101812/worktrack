import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/dimens.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/work_entry.dart';
import '../../../providers/entries_provider.dart';

class EntryListTile extends ConsumerWidget {
  final WorkEntry entry;
  const EntryListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final clientColor = parseHexColor(entry.clientColor, c.primary);
    final hasProject =
        entry.projectName != null && entry.projectName!.isNotEmpty;
    final displayTitle = hasProject
        ? '${entry.clientName} • ${entry.projectName}'
        : entry.clientName;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: Spacing.s4),
        decoration: BoxDecoration(
          color: c.error,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacing.s20),
        child: Icon(Icons.delete_outline_rounded,
            color: c.onPrimary, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppDialog.background(context),
            shape: AppDialog.shape(context),
            title: const Text('Kaydı Sil'),
            content: const Text('Bu kaydı silmek istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: c.error),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(entriesProvider.notifier).deleteEntry(entry.id),
      child: AppCard(
        margin: const EdgeInsets.symmetric(vertical: Spacing.s4),
        padding: const EdgeInsets.all(Spacing.s16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: clientColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Center(
                child: Text(
                  entry.clientName.isNotEmpty
                      ? entry.clientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: clientColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.workType,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.durationHours.toStringAsFixed(1)} sa',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (!entry.synced)
                      Icon(PhosphorIcons.cloudArrowUp(),
                          size: 12, color: c.orange)
                    else
                      Icon(PhosphorIcons.cloudCheck(),
                          size: 12, color: c.primary),
                    const SizedBox(width: 4),
                    Text(
                      entry.startTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
