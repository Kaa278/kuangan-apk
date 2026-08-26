import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:kuangan/shared/models/dashboard_data.dart';
import 'package:kuangan/shared/models/wallet.dart';
import 'package:kuangan/shared/utils/date.dart';
import 'package:kuangan/features/dashboard/dashboard_provider.dart';
import 'package:kuangan/features/dashboard/balance_card.dart';
import 'package:kuangan/features/dashboard/wallet_card.dart';
import 'package:kuangan/features/dashboard/stat_card.dart';
import 'package:kuangan/features/dashboard/bar_chart_widget.dart';
import 'package:kuangan/features/dashboard/donut_chart_widget.dart';
import 'package:kuangan/features/transactions/transaction_modal.dart';
import 'package:kuangan/shared/utils/responsive.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  DashboardData _getMockData() {
    return DashboardData(
      totalBalance: 12500000,
      monthly: MonthlyStats(income: 5000000, expense: 2000000),
      wallets: [
        Wallet(
          id: '1',
          name: 'MOCK Wallet',
          balance: 5000000,
          color: '#2563EB',
          icon: 'wallet',
        ),
        Wallet(
          id: '2',
          name: 'MOCK Wallet 2',
          balance: 7500000,
          color: '#10B981',
          icon: 'account_balance_wallet',
        ),
      ],
      last6Months: [
        MonthlyFlow(month: '1/2026', income: 5000000, expense: 2000000)
      ],
      topCategories: [
        TopCategory(
            name: 'MOCK',
            color: '#2563EB',
            icon: '📝',
            amount: 1000000,
            percentage: 50)
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: dashboardAsync.when(
            data: (data) => _buildContent(context, data),
            loading: () => Skeletonizer(
              enabled: true,
              child: _buildContent(context, _getMockData()),
            ),
            error: (err, stack) => _buildErrorState(context, ref, err),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 86.0),
        child: FloatingActionButton(
          onPressed: () => TransactionModal.show(context),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 64, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ops! Ada Masalah',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat data dashboard. Mohon cek koneksi atau database kamu.\n\nError: ${err.toString().split('\n').first}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic data) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final width = MediaQuery.sizeOf(context).width;
    final walletCardWidth = width < 360 ? 148.0 : 170.0;
    final statCrossAxisCount = width < 360 ? 1 : 2;
    final statAspectRatio = width < 360 ? 2.3 : 1.2;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(context),
              const SizedBox(height: 32),
              BalanceCard(
                totalBalance: data.totalBalance,
                monthlyIncome: data.monthly.income,
                monthlyExpense: data.monthly.expense,
              ),
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'Dompet Saya', () {}),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: data.wallets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) => WalletCard(
                    wallet: data.wallets[index],
                    width: walletCardWidth,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'Ringkasan Statistik', null),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: statCrossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: statAspectRatio,
                children: [
                  StatCard(
                    title: 'Rata-rata/Hari',
                    value: 'Rp 45rb',
                    icon: Icons.calendar_today_rounded,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: 'Bulan Ini',
                    value: '+12%',
                    icon: Icons.trending_up_rounded,
                    color: Colors.teal,
                  ),
                  StatCard(
                    title: 'Prediksi',
                    value: 'Rp 2.1jt',
                    icon: Icons.insights_rounded,
                    color: Colors.indigo,
                  ),
                  StatCard(
                    title: 'Budget',
                    value: 'Aman',
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'Laporan Arus Kas', null),
              const SizedBox(height: 16),
              BarChartWidget(data: data.last6Months),
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'Pengeluaran Terbesar', null),
              const SizedBox(height: 16),
              DonutChartWidget(topCategories: data.topCategories),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isCompact = Responsive.isCompact(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, Selamat Sejahtera!',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatDateFull(DateTime.now()),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isCompact ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback? onTap) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Lihat Semua'),
          ),
      ],
    );
  }
}
