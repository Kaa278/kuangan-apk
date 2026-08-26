import 'package:flutter/material.dart';
import 'package:kuangan/shared/models/wallet.dart';
import 'package:kuangan/shared/utils/currency.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final double? width;

  const WalletCard({super.key, required this.wallet, this.width});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(wallet.color.replaceFirst('#', '0xFF')));

    return Container(
      width: width ?? 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const Icon(Icons.more_horiz_rounded,
                  color: Color(0xFF94A3B8), size: 18),
            ],
          ),
          const Spacer(),
          Text(
            wallet.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            formatIDR(wallet.balance),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
