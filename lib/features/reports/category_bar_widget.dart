import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kuangan/shared/models/dashboard_data.dart';
import 'package:kuangan/shared/utils/currency.dart';

class CategoryBarWidget extends StatelessWidget {
  final TopCategory category;
  final double maxAmount;

  const CategoryBarWidget({
    super.key,
    required this.category,
    required this.maxAmount,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxAmount > 0 ? category.amount / maxAmount : 0.0;
    final color = Color(int.parse(category.color.replaceFirst('#', '0xFF')));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                formatIDR(category.amount),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .shimmer(duration: 2.seconds, color: Colors.white24)
                    .scaleX(
                        begin: 0,
                        end: 1,
                        duration: 800.ms,
                        curve: Curves.easeOutCubic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
