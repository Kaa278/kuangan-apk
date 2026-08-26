import 'package:flutter/material.dart';

class FilterPanel extends StatelessWidget {
  final String selectedType; // 'Semua' | 'Income' | 'Expense'
  final Function(String) onTypeChanged;

  const FilterPanel({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTypeChip(context, 'Semua'),
          const SizedBox(width: 10),
          _buildTypeChip(context, 'Pemasukan'),
          const SizedBox(width: 10),
          _buildTypeChip(context, 'Pengeluaran'),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String label) {
    final isSelected = selectedType == label;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => onTypeChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
