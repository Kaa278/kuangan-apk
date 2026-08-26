import 'package:flutter/material.dart';
import 'package:kuangan/shared/utils/currency.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final balanceFontSize = isCompact ? 28.0 : 34.0;
    final cardPadding = isCompact ? 20.0 : 28.0;
    final miniStatPadding = isCompact ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            const Color(0xFF6366F1), // Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Saldo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(Icons.waves_rounded,
                        color: Colors.white.withValues(alpha: 0.3), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatIDR(totalBalance),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: balanceFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: isCompact ? 24 : 32),
                Container(
                  padding: EdgeInsets.all(miniStatPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Flex(
                    direction: isCompact ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        flex: isCompact ? 0 : 1,
                        child: _buildMiniStat(
                          context,
                          label: 'Pemasukan',
                          amount: monthlyIncome,
                          icon: Icons.south_west_rounded,
                          color: const Color(0xFF34D399),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(
                          vertical: isCompact ? 12 : 0,
                          horizontal: isCompact ? 0 : 16,
                        ),
                        height: isCompact ? 1 : 30,
                        width: isCompact ? double.infinity : 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      Expanded(
                        flex: isCompact ? 0 : 1,
                        child: _buildMiniStat(
                          context,
                          label: 'Pengeluaran',
                          amount: monthlyExpense,
                          icon: Icons.north_east_rounded,
                          color: const Color(0xFFF87171),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          child: Text(
            formatIDR(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
