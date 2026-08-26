import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kuangan/shared/models/dashboard_data.dart';
import 'package:kuangan/shared/utils/currency.dart';

class DonutChartWidget extends StatelessWidget {
  final List<TopCategory> topCategories;

  const DonutChartWidget({super.key, required this.topCategories});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final chartSize = isCompact ? 124.0 : 150.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Pengeluaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Flex(
            direction: isCompact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: chartSize,
                width: chartSize,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: isCompact ? 30 : 40,
                    sections: topCategories.map((e) {
                      final color =
                          Color(int.parse(e.color.replaceFirst('#', '0xFF')));
                      return PieChartSectionData(
                        color: color,
                        value: e.amount,
                        title: '${e.percentage.toInt()}%',
                        radius: isCompact ? 42 : 50,
                        titleStyle: TextStyle(
                          fontSize: isCompact ? 10 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 20 : 0, width: isCompact ? 0 : 24),
              Expanded(
                flex: isCompact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topCategories
                      .map((e) => _buildLegendItem(e, isDark))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(TopCategory category, bool isDark) {
    final color = Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatIDR(category.amount, compact: true),
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
