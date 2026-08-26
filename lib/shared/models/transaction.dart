import 'wallet.dart';
import 'category.dart';

class Transaction {
  final String id;
  final String type; // income | expense
  final String source; // manual | ai_scan
  final double amount;
  final String? note;
  final String? store;
  final DateTime date;
  final Category? category;
  final Wallet? wallet;

  Transaction({
    required this.id,
    required this.type,
    required this.source,
    required this.amount,
    this.note,
    this.store,
    required this.date,
    this.category,
    this.wallet,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      source: (json['source'] ?? 'manual') as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      store: json['store'] as String?,
      date: DateTime.parse(json['date'] as String),
      category: (json['categories'] ?? json['category']) != null
          ? Category.fromJson(
              (json['categories'] ?? json['category']) as Map<String, dynamic>)
          : null,
      wallet: (json['wallets'] ?? json['wallet']) != null
          ? Wallet.fromJson(
              (json['wallets'] ?? json['wallet']) as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'source': source,
        'amount': amount,
        'note': note,
        'store': store,
        'date': date.toIso8601String(),
        'category': category?.toJson(),
        'wallet': wallet?.toJson(),
      };
}
