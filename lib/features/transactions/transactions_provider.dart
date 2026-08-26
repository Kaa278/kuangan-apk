import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import 'package:kuangan/shared/models/category.dart';
import 'package:kuangan/shared/demo/demo_data.dart';
import 'package:kuangan/features/auth/auth_provider.dart';
import 'package:kuangan/shared/models/transaction.dart';
import 'package:kuangan/features/settings/settings_provider.dart';

const _uuid = Uuid();

class TransactionsState {
  final List<Transaction> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  TransactionsState({
    required this.items,
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  TransactionsState copyWith({
    List<Transaction>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return TransactionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error ?? this.error,
    );
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  return TransactionsNotifier(ref, userId);
});

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final Ref _ref;
  final String? _userId;
  final _supabase = sb.Supabase.instance.client;
  sb.RealtimeChannel? _subscription;
  Timer? _refreshTimer;

  TransactionsNotifier(this._ref, this._userId)
      : super(TransactionsState(items: [])) {
    if (isDemoUser(_userId)) {
      state = state.copyWith(items: buildDemoTransactions(), hasMore: false);
    } else if (_userId != null) {
      fetch();
      _setupRealtime();

      // Fallback auto-refresh every 30 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        fetchSilent();
      });
    }
  }

  void _setupRealtime() {
    _subscription = _supabase
        .channel('public:transactions:$_userId')
        .onPostgresChanges(
            event: sb.PostgresChangeEvent.all,
            schema: 'public',
            table: 'transactions',
            filter: sb.PostgresChangeFilter(
              type: sb.PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _userId!,
            ),
            callback: (sb.PostgresChangePayload payload) {
              fetchSilent();
            })
        .subscribe();
  }

  Future<void> fetchSilent() async {
    if (_userId == null) return;
    if (isDemoUser(_userId)) return;
    try {
      final from = 0;
      final to = (state.page > 1 ? state.page * 20 : 20) - 1;

      final data = await _supabase
          .from('transactions')
          .select('*, categories(*), wallets(*)')
          .eq('user_id', _userId!)
          .order('date', ascending: false)
          .range(from, to) as List<dynamic>;

      final List<Transaction> newItems = data
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        items: newItems,
      );
    } catch (e) {
      debugPrint('SILENT TRANSACTIONS FETCH ERROR: $e');
    }
  }

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading || (!refresh && !state.hasMore) || _userId == null) {
      return;
    }
    if (isDemoUser(_userId)) {
      state = state.copyWith(
        items: state.items.isEmpty ? buildDemoTransactions() : state.items,
        hasMore: false,
        isLoading: false,
        page: 1,
      );
      return;
    }

    if (refresh) {
      state =
          state.copyWith(items: [], page: 1, hasMore: true, isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    final userId = _userId!;
    try {
      final from = (state.page - 1) * 20;
      final to = from + 19;

      final data = await _supabase
          .from('transactions')
          .select('*, categories(*), wallets(*)')
          .eq('user_id', userId)
          .order('date', ascending: false)
          .range(from, to) as List<dynamic>;

      final List<Transaction> newItems = data
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        page: state.page + 1,
        hasMore: newItems.length == 20,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('TRANSACTIONS FETCH ERROR: $e');
      state = state.copyWith(isLoading: false, error: 'Gagal memuat transaksi');
    }
  }

  Future<bool> addTransaction({
    required double amount,
    required String type,
    required String source,
    required DateTime date,
    required String? categoryId,
    required String? walletId,
    String? note,
    String? store,
  }) async {
    if (_userId == null) return false;
    if (isDemoUser(_userId)) {
      final settings = _ref.read(settingsProvider);
      Transaction? demoTransaction;
      for (final wallet in settings.wallets) {
        if (wallet.id == walletId) {
          Category? selectedCategory;
          for (final category in settings.categories) {
            if (category.id == categoryId) {
              selectedCategory = category;
              break;
            }
          }

          demoTransaction = Transaction(
            id: _uuid.v4(),
            type: type,
            source: source,
            amount: amount,
            note: note,
            store: store,
            date: date,
            category: selectedCategory,
            wallet: wallet,
          );
          break;
        }
      }

      demoTransaction ??= Transaction(
        id: _uuid.v4(),
        type: type,
        source: source,
        amount: amount,
        note: note,
        store: store,
        date: date,
      );

      state = state.copyWith(items: [demoTransaction, ...state.items]);
      if (walletId != null) {
        _ref.read(settingsProvider.notifier).applyDemoWalletBalanceDelta(
              walletId: walletId,
              amount: amount,
              type: type,
            );
      }
      return true;
    }

    try {
      final payload = {
        'id': _uuid.v4(),
        'user_id': _userId,
        'amount': amount,
        'type': type,
        'source': source,
        'date': date.toIso8601String(),
        'category_id': categoryId,
        'wallet_id': walletId,
        'note': note,
        'store': store,
      };

      final response = await _supabase
          .from('transactions')
          .insert(payload)
          .select('*, categories(*), wallets(*)')
          .single();

      final newTransaction = Transaction.fromJson(response);

      // Update the wallet balance in the database
      if (walletId != null) {
        final walletData = await _supabase
            .from('wallets')
            .select('balance')
            .eq('id', walletId)
            .single();

        final currentBalance = (walletData['balance'] as num).toDouble();
        final newBalance = type == 'income'
            ? currentBalance + amount
            : currentBalance - amount;

        await _supabase
            .from('wallets')
            .update({'balance': newBalance}).eq('id', walletId);
      }

      // Optimistically update the local state by adding it to the top of the list
      state = state.copyWith(
        items: [newTransaction, ...state.items],
      );

      return true;
    } catch (e) {
      debugPrint('ADD TRANSACTION ERROR: $e');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    if (_userId == null) return false;
    if (isDemoUser(_userId)) {
      final txToRestore = state.items.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Transaction local not found'),
      );
      if (txToRestore.wallet?.id != null) {
        _ref.read(settingsProvider.notifier).applyDemoWalletBalanceDelta(
              walletId: txToRestore.wallet!.id,
              amount: txToRestore.amount,
              type: txToRestore.type == 'income' ? 'expense' : 'income',
            );
      }
      state = state.copyWith(
        items: state.items.where((t) => t.id != id).toList(),
      );
      return true;
    }
    try {
      // 1. Fetch transaction details to restore balance
      final txToRestore = state.items.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Transaction local not found'),
      );

      if (txToRestore.wallet?.id != null) {
        final walletId = txToRestore.wallet!.id;
        final amount = txToRestore.amount;
        final type = txToRestore.type;

        // Fetch current wallet balance
        final walletData = await _supabase
            .from('wallets')
            .select('balance')
            .eq('id', walletId)
            .single();

        final currentBalance = (walletData['balance'] as num).toDouble();
        final newBalance = type == 'income'
            ? currentBalance - amount
            : currentBalance + amount;

        await _supabase
            .from('wallets')
            .update({'balance': newBalance}).eq('id', walletId);
      }

      // 2. Delete the transaction
      await _supabase
          .from('transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      // 3. Update local state
      state = state.copyWith(
        items: state.items.where((t) => t.id != id).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('TRANSACTIONS DELETE ERROR: $e');
      return false;
    }
  }

  @override
  void dispose() {
    if (!isDemoUser(_userId)) {
      _refreshTimer?.cancel();
      _subscription?.unsubscribe();
    }
    super.dispose();
  }
}
