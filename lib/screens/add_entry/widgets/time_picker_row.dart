import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/dimens.dart';
import '../../../core/theme.dart';

class TimePickerRow extends StatelessWidget {
  final String startTime;
  final String endTime;
  final ValueChanged<String> onStartTimeChanged;
  final ValueChanged<String> onEndTimeChanged;

  const TimePickerRow({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  /// Safely parses "HH:mm" into minutes-since-midnight (null on bad input).
  static int? _toMinutes(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final startMin = _toMinutes(startTime);
    final endMin = _toMinutes(endTime);
    final diff = (endMin != null && startMin != null) ? endMin - startMin : 0;
    final adjusted = diff < 0 ? diff + 24 * 60 : diff;
    final duration = adjusted / 60.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTimePicker(context, 'BAŞLANGIÇ', startTime, onStartTimeChanged, c)),
            const SizedBox(width: Spacing.s12),
            Expanded(child: _buildTimePicker(context, 'BİTİŞ', endTime, onEndTimeChanged, c)),
          ],
        ),
        const SizedBox(height: Spacing.s16),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Spacing.s12, horizontal: Spacing.s20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.clock(), size: 16, color: c.primary),
              const SizedBox(width: Spacing.s8),
              Text(
                'Toplam: ${duration > 0 ? duration.toStringAsFixed(1) : "0.0"} saat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String label,
    String time,
    ValueChanged<String> onChanged,
    AppPalette c,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Spacing.s4, bottom: Spacing.s8),
          child: Text(
            label,
            style: AppTexts.eyebrow(context),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final min = _toMinutes(time) ?? (9 * 60);
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: min ~/ 60, minute: min % 60),
            );
            if (picked != null) {
              onChanged(
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
              );
            }
          },
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: Spacing.s16, horizontal: Spacing.s12),
            child: Center(
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.textMain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
