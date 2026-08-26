import 'package:flutter/material.dart';
import 'package:kuangan/shared/models/transaction.dart';
import 'package:kuangan/shared/utils/currency.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = transaction.category;
    final color = category != null
        ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
        : Theme.of(context).primaryColor;

    final isIncome = transaction.type == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: (category != null && category.icon.isNotEmpty)
              ? Text(
                  category.icon,
                  style: const TextStyle(fontSize: 20),
                )
              : Icon(
                  isIncome ? Icons.add_rounded : Icons.remove_rounded,
                  color: color,
                  size: 22,
                ),
        ),
        title: Text(
          transaction.store ?? category?.name ?? 'Tanpa Kategori',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (transaction.wallet != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          transaction.wallet!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              if (transaction.source == 'ai_scan') ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 10, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 2),
                      const Text(
                        'Kathlyn Scan',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Container(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            formatIDRSigned(
                isIncome ? transaction.amount : -transaction.amount),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}
