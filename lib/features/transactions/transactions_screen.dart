import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:kuangan/shared/models/transaction.dart';
import 'package:kuangan/shared/models/wallet.dart';
import 'package:kuangan/shared/models/category.dart';
import 'package:kuangan/shared/utils/date.dart';
import 'package:kuangan/shared/widgets/app_feedback.dart';
import 'package:kuangan/features/transactions/transactions_provider.dart';
import 'package:kuangan/features/transactions/transaction_tile.dart';
import 'package:kuangan/features/transactions/filter_panel.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedType = 'Semua';
  final ScrollController _scrollController = ScrollController();

  List<Transaction> _getMockTransactions() {
    return List.generate(
      5,
      (index) => Transaction(
        id: index.toString(),
        type: index % 2 == 0 ? 'expense' : 'income',
        source: 'manual',
        amount: 50000.0 * (index + 1),
        note: 'Mock transaction note for skeleton',
        store: 'Mock Store',
        date: DateTime.now(),
        category: Category(
          id: '1',
          name: 'Makan',
          color: '#2563EB',
          icon: 'restaurant',
          type: 'expense',
        ),
        wallet: Wallet(
          id: '1',
          name: 'Dompet',
          color: '#2563EB',
          icon: 'wallet',
          balance: 1000000,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsProvider.notifier).fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider);

    // Apply filter locally
    final filteredItems = state.items.where((item) {
      if (_selectedType == 'Pemasukan') return item.type == 'income';
      if (_selectedType == 'Pengeluaran') return item.type == 'expense';
      return true; // 'Semua'
    }).toList();

    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
            child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(transactionsProvider.notifier).fetch(refresh: true);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FilterPanel(
                    selectedType: _selectedType,
                    onTypeChanged: (type) {
                      setState(() => _selectedType = type);
                      // Actual filtering logic could be added to provider
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 8),
                sliver: state.items.isEmpty && state.isLoading
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final mockItems = _getMockTransactions();
                            final transaction = mockItems[index];
                            return Skeletonizer(
                              enabled: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index == 0)
                                    _buildDateHeader(DateTime.now()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: TransactionTile(
                                        transaction: transaction),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: 5,
                        ),
                      )
                    : filteredItems.isEmpty
                        ? SliverFillRemaining(
                            child: _buildEmptyState(_selectedType))
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == filteredItems.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                  );
                                }

                                final transaction = filteredItems[index];
                                final showHeader = index == 0 ||
                                    formatDate(transaction.date) !=
                                        formatDate(
                                            filteredItems[index - 1].date);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (showHeader)
                                      _buildDateHeader(transaction.date),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Dismissible(
                                        key: Key(transaction.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade400,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          alignment: Alignment.centerRight,
                                          padding:
                                              const EdgeInsets.only(right: 20),
                                          child: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white,
                                              size: 28),
                                        ),
                                        confirmDismiss: (_) async {
                                          return await showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title:
                                                  const Text('Hapus Catatan?'),
                                              content: const Text(
                                                  'Tindakan ini juga akan mengembalikan saldo di dompet kamu.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(false),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(true),
                                                  style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red),
                                                  child: const Text('Hapus'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        onDismissed: (_) {
                                          ref
                                              .read(
                                                  transactionsProvider.notifier)
                                              .delete(transaction.id);
                                          showAppFeedback(
                                            context,
                                            title: 'Catatan Dihapus',
                                            message:
                                                'Transaksi sudah dihapus dari daftar.',
                                            type: AppFeedbackType.info,
                                          );
                                        },
                                        child: TransactionTile(
                                            transaction: transaction),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              childCount: filteredItems.length +
                                  (state.hasMore ? 1 : 0),
                            ),
                          ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        )));
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        formatDate(date).toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filterType) {
    String title = 'Belum Ada Catatan';
    String message =
        'Semua riwayat pengeluaran dan pemasukanmu akan muncul di sini.';

    if (filterType == 'Pemasukan') {
      title = 'Belum Ada Pemasukan';
      message = 'Riwayat pemasukanmu akan muncul di sini.';
    } else if (filterType == 'Pengeluaran') {
      title = 'Belum Ada Pengeluaran';
      message = 'Riwayat pengeluaranmu akan muncul di sini.';
    }

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 64, color: Colors.blue.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
