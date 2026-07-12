import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';

class WorkTypeSelector extends StatelessWidget {
  final String selectedWorkType;
  final ValueChanged<String> onWorkTypeSelected;

  const WorkTypeSelector({
    super.key,
    required this.selectedWorkType,
    required this.onWorkTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.workTypes.map((type) {
        final isSelected = selectedWorkType == type;
        return GestureDetector(
          onTap: () => onWorkTypeSelected(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? c.primary : c.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? c.primary : c.cardBorder,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? c.onPrimary : c.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
