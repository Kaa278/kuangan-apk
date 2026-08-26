import 'package:kuangan/shared/models/category.dart';
import 'package:kuangan/shared/models/dashboard_data.dart';
import 'package:kuangan/shared/models/transaction.dart';
import 'package:kuangan/shared/models/user.dart';
import 'package:kuangan/shared/models/wallet.dart';

const demoUserId = 'demo-local-user';
const demoEmail = 'lorem@gmail.com';
const demoPassword = 'kaa278';

final demoUser = User(
  id: demoUserId,
  name: 'Lorem Demo',
  email: demoEmail,
);

List<Wallet> buildDemoWallets() {
  return [
    Wallet(
      id: 'demo-wallet-main',
      name: 'Dompet Utama',
      color: '#0F766E',
      icon: '💳',
      balance: 2450000,
    ),
    Wallet(
      id: 'demo-wallet-cash',
      name: 'Cash Harian',
      color: '#F59E0B',
      icon: '💵',
      balance: 375000,
    ),
  ];
}

List<Category> buildDemoCategories() {
  return [
    Category(
      id: 'demo-cat-food',
      name: 'Makanan & Minuman',
      color: '#F97316',
      icon: '🍜',
      type: 'expense',
    ),
    Category(
      id: 'demo-cat-transport',
      name: 'Transportasi',
      color: '#3B82F6',
      icon: '🛵',
      type: 'expense',
    ),
    Category(
      id: 'demo-cat-bills',
      name: 'Tagihan',
      color: '#8B5CF6',
      icon: '📄',
      type: 'expense',
    ),
    Category(
      id: 'demo-cat-income',
      name: 'Gaji',
      color: '#10B981',
      icon: '💼',
      type: 'income',
    ),
  ];
}

List<Transaction> buildDemoTransactions() {
  final wallets = buildDemoWallets();
  final categories = buildDemoCategories();

  Wallet walletById(String id) => wallets.firstWhere((item) => item.id == id);
  Category categoryById(String id) =>
      categories.firstWhere((item) => item.id == id);

  return [
    Transaction(
      id: 'demo-tx-1',
      type: 'expense',
      source: 'manual',
      amount: 28000,
      note: 'Makan siang tim',
      store: 'Warteg Bahari',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      category: categoryById('demo-cat-food'),
      wallet: walletById('demo-wallet-main'),
    ),
    Transaction(
      id: 'demo-tx-2',
      type: 'expense',
      source: 'manual',
      amount: 15000,
      note: 'Ojol ke kantor',
      store: 'Gojek',
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: categoryById('demo-cat-transport'),
      wallet: walletById('demo-wallet-cash'),
    ),
    Transaction(
      id: 'demo-tx-3',
      type: 'income',
      source: 'manual',
      amount: 4200000,
      note: 'Gaji bulanan',
      store: 'PT Demo Sentosa',
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: categoryById('demo-cat-income'),
      wallet: walletById('demo-wallet-main'),
    ),
    Transaction(
      id: 'demo-tx-4',
      type: 'expense',
      source: 'manual',
      amount: 325000,
      note: 'Bayar listrik',
      store: 'PLN Mobile',
      date: DateTime.now().subtract(const Duration(days: 4)),
      category: categoryById('demo-cat-bills'),
      wallet: walletById('demo-wallet-main'),
    ),
  ];
}

DashboardData buildDemoDashboardData({
  required List<Wallet> wallets,
  required List<Transaction> transactions,
}) {
  final totalBalance =
      wallets.fold<double>(0, (sum, wallet) => sum + wallet.balance);
  final now = DateTime.now();
  final currentMonthTransactions = transactions.where(
    (tx) => tx.date.year == now.year && tx.date.month == now.month,
  );

  double income = 0;
  double expense = 0;
  final Map<String, double> categoryTotals = {};
  final Map<String, Category> categoryIndex = {};

  for (final tx in currentMonthTransactions) {
    if (tx.type == 'income') {
      income += tx.amount;
    } else {
      expense += tx.amount;
      final category = tx.category;
      if (category != null) {
        categoryTotals[category.id] =
            (categoryTotals[category.id] ?? 0) + tx.amount;
        categoryIndex[category.id] = category;
      }
    }
  }

  final topCategories = categoryTotals.entries.map((entry) {
    final category = categoryIndex[entry.key]!;
    return TopCategory(
      name: category.name,
      color: category.color,
      icon: category.icon,
      amount: entry.value,
      percentage: expense == 0 ? 0 : (entry.value / expense) * 100,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final last6Months = List.generate(6, (index) {
    final monthDate = DateTime(now.year, now.month - index, 1);
    final monthTx = transactions.where(
      (tx) =>
          tx.date.year == monthDate.year && tx.date.month == monthDate.month,
    );
    double monthIncome = 0;
    double monthExpense = 0;
    for (final tx in monthTx) {
      if (tx.type == 'income') {
        monthIncome += tx.amount;
      } else {
        monthExpense += tx.amount;
      }
    }
    return MonthlyFlow(
      month: '${monthDate.month}/${monthDate.year}',
      income: monthIncome,
      expense: monthExpense,
    );
  });

  return DashboardData(
    totalBalance: totalBalance,
    monthly: MonthlyStats(income: income, expense: expense),
    wallets: wallets,
    last6Months: last6Months,
    topCategories: topCategories,
  );
}

bool isDemoUser(String? userId) => userId == demoUserId;
