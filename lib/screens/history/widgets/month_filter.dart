import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/midnight_widgets.dart';
import '../../../core/theme.dart';

class MonthFilter extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthFilter({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MidnightCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: PhosphorIcons.caretLeft(),
            onTap: () => onMonthChanged(
              DateTime(selectedMonth.year, selectedMonth.month - 1),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy', 'tr').format(selectedMonth).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.1,
              color: AppColors.textPrimary,
            ),
          ),
          _NavButton(
            icon: PhosphorIcons.caretRight(),
            onTap: () => onMonthChanged(
              DateTime(selectedMonth.year, selectedMonth.month + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
