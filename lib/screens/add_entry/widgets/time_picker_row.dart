import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/midnight_widgets.dart';
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
    final duration = (startMin != null && endMin != null)
        ? (endMin - startMin) / 60.0
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTimePicker(context, 'BAŞLANGIÇ', startTime, onStartTimeChanged, c)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker(context, 'BİTİŞ', endTime, onEndTimeChanged, c)),
          ],
        ),
        const SizedBox(height: 16),
        MidnightCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.clock(), size: 16, color: c.primary),
              const SizedBox(width: 10),
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: c.textMuted,
            ),
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
          child: MidnightCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
