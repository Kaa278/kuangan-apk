import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:kuangan/shared/demo/demo_data.dart';
import 'package:kuangan/features/auth/auth_provider.dart';
import 'package:kuangan/shared/models/dashboard_data.dart';
import 'package:kuangan/shared/models/wallet.dart';
import 'package:kuangan/features/transactions/transactions_provider.dart';
import 'package:kuangan/features/settings/settings_provider.dart';

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData>(() {
  return DashboardNotifier();
});

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  final _supabase = sb.Supabase.instance.client;
  Timer? _refreshTimer;

  @override
  Future<DashboardData> build() async {
    // Watch auth state to react to login/logout
    final authState = ref.watch(authProvider);

    // If not authenticated, we shouldn't even be here (handled by GoRouter)
    // but we check anyway to avoid throwing early exceptions.
    if (authState.status != AuthStatus.authenticated ||
        authState.user == null) {
      // Return a dummy state or wait
      return Completer<DashboardData>().future; // Stay in loading
    }

    ref.listen(transactionsProvider, (previous, next) {
      refresh();
    });

    ref.listen(settingsProvider, (previous, next) {
      refresh();
    });

    if (isDemoUser(authState.user!.id)) {
      final settingsState = ref.read(settingsProvider);
      final transactionsState = ref.read(transactionsProvider);
      return buildDemoDashboardData(
        wallets: settingsState.wallets,
        transactions: transactionsState.items,
      );
    }

    // Initial fetch
    final data = await _fetchData(authState.user!.id);

    // Setup auto-refresh every 30 seconds
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      refresh();
    });

    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    return data;
  }

  Future<DashboardData> _fetchData(String userId) async {
    try {
      // 1. Fetch Wallets
      final List<Map<String, dynamic>> walletsJson =
          await _supabase.from('wallets').select().eq('user_id', userId);

      final wallets = walletsJson.map((e) => Wallet.fromJson(e)).toList();
      final double totalBalance = wallets.fold(0, (sum, w) => sum + w.balance);

      // 2. Fetch Transactions for the current month with category join
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      final List<Map<String, dynamic>> currentMonthJson = await _supabase
          .from('transactions')
          .select('*, categories(*)')
          .eq('user_id', userId)
          .gte('date', firstDayOfMonth.toIso8601String());

      double income = 0;
      double expense = 0;
      for (var item in currentMonthJson) {
        final amount = (item['amount'] as num).toDouble();
        if (item['type'] == 'income') {
          income += amount;
        } else {
          expense += amount;
        }
      }

      // 3. Last 6 months
      final List<MonthlyFlow> last6Months = [
        MonthlyFlow(
          month: '${now.month}/${now.year}',
          income: income,
          expense: expense,
        )
      ];

      // 4. Top Categories aggregation
      final Map<String, _CategorySummary> categoryMap = {};
      for (var item in currentMonthJson) {
        if (item['type'] == 'expense') {
          final categoryData = item['categories'] as Map<String, dynamic>?;
          final categoryName = categoryData?['name'] as String? ?? 'Lainnya';
          final categoryColor = categoryData?['color'] as String? ?? '#94A3B8';
          final categoryIcon = categoryData?['icon'] as String? ?? '📝';
          final amount = (item['amount'] as num).toDouble();

          if (categoryMap.containsKey(categoryName)) {
            categoryMap[categoryName]!.amount += amount;
          } else {
            categoryMap[categoryName] = _CategorySummary(
              name: categoryName,
              color: categoryColor,
              icon: categoryIcon,
              amount: amount,
            );
          }
        }
      }

      final List<TopCategory> topCategories = categoryMap.values
          .map((e) => TopCategory(
                name: e.name,
                color: e.color,
                icon: e.icon,
                amount: e.amount,
                percentage: expense > 0 ? (e.amount / expense * 100) : 0,
              ))
          .toList();

      // Sort by amount descending
      topCategories.sort((a, b) => b.amount.compareTo(a.amount));

      return DashboardData(
        totalBalance: totalBalance,
        monthly: MonthlyStats(income: income, expense: expense),
        wallets: wallets,
        last6Months: last6Months,
        topCategories: topCategories,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId != null) {
      if (isDemoUser(userId)) {
        final settingsState = ref.read(settingsProvider);
        final transactionsState = ref.read(transactionsProvider);
        state = AsyncValue.data(
          buildDemoDashboardData(
            wallets: settingsState.wallets,
            transactions: transactionsState.items,
          ),
        );
        return;
      }
      // Fetch in the background and update state without triggering Skeletonizer
      final result = await AsyncValue.guard(() => _fetchData(userId));

      // Only assign state if successful or if we don't have existing data
      // This prevents disruptive error screens on temporary network drops
      if (result.hasValue || !state.hasValue) {
        state = result;
      }
    }
  }
}

class _CategorySummary {
  final String name;
  final String color;
  final String icon; // Field added
  double amount;

  _CategorySummary({
    required this.name,
    required this.color,
    required this.icon,
    required this.amount,
  });
}
