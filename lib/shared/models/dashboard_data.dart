import 'wallet.dart';

class DashboardData {
  final double totalBalance;
  final MonthlyStats monthly;
  final List<Wallet> wallets;
  final List<MonthlyFlow> last6Months;
  final List<TopCategory> topCategories;

  DashboardData({
    required this.totalBalance,
    required this.monthly,
    required this.wallets,
    required this.last6Months,
    required this.topCategories,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalBalance: (json['totalBalance'] as num).toDouble(),
      monthly: MonthlyStats.fromJson(json['monthly'] as Map<String, dynamic>),
      wallets: (json['wallets'] as List<dynamic>)
          .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
          .toList(),
      last6Months: (json['last6Months'] as List<dynamic>)
          .map((e) => MonthlyFlow.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCategories: (json['topCategories'] as List<dynamic>)
          .map((e) => TopCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MonthlyStats {
  final double income;
  final double expense;

  MonthlyStats({required this.income, required this.expense});

  double get net => income - expense;
  double get avgPerDay =>
      expense / 30; // Approximation or use actual day count if available

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );
  }
}

class MonthlyFlow {
  final String month;
  final double income;
  final double expense;

  MonthlyFlow({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  factory MonthlyFlow.fromJson(Map<String, dynamic> json) {
    return MonthlyFlow(
      month: json['month'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );
  }
}

class TopCategory {
  final String name;
  final String color;
  final String icon; // Added icon field
  final double amount;
  final double percentage;

  TopCategory({
    required this.name,
    required this.color,
    required this.icon,
    required this.amount,
    required this.percentage,
  });

  factory TopCategory.fromJson(Map<String, dynamic> json) {
    return TopCategory(
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String? ?? '📝', // Parse icon
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}
