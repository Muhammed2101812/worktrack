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

  @override
  Widget build(BuildContext context) {
    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();
    final duration = (endParts[0] * 60 + endParts[1] - startParts[0] * 60 - startParts[1]) / 60.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTimePicker(context, 'BAŞLANGIÇ', startTime, onStartTimeChanged)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker(context, 'BİTİŞ', endTime, onEndTimeChanged)),
          ],
        ),
        const SizedBox(height: 16),
        MidnightCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.clock(), size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Toplam: ${duration > 0 ? duration.toStringAsFixed(1) : "0.0"} saat',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textMuted,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final parts = time.split(':').map(int.parse).toList();
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
