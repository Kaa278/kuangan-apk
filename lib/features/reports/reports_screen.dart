import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuangan/features/dashboard/dashboard_provider.dart';
import 'package:kuangan/features/dashboard/bar_chart_widget.dart'; // Added import
import 'package:skeletonizer/skeletonizer.dart';
import 'package:kuangan/shared/utils/currency.dart';
import 'package:kuangan/shared/models/dashboard_data.dart';
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  DashboardData _getMockData() {
    return DashboardData(
      totalBalance: 10000000,
      monthly: MonthlyStats(income: 5000000, expense: 2000000),
      wallets: [],
      last6Months: [
        MonthlyFlow(month: '1/2026', income: 5000000, expense: 2000000)
      ],
      topCategories: [
        TopCategory(
            name: 'MOCK Category',
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
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Text(
                    'Laporan Analistik',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: dashboardAsync.when(
                  data: (data) => SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMainMetricCard(context, data),
                      const SizedBox(height: 40),
                      _buildSectionTitle('Arus Kas Bulanan'),
                      const SizedBox(height: 16),
                      BarChartWidget(
                          data: data.last6Months), // Swapped out Placeholder
                      const SizedBox(height: 40),
                      _buildSectionTitle('Bulan Ini per Kategori'),
                      const SizedBox(height: 16),
                      ...data.topCategories
                          .map((cat) => _buildCategoryRow(context, cat)),
                      const SizedBox(height: 100),
                    ]),
                  ),
                  loading: () => SliverToBoxAdapter(
                    child: Skeletonizer(
                      enabled: true,
                      child: Column(
                        children: [
                          _buildMainMetricCard(context, _getMockData()),
                          const SizedBox(height: 40),
                          Align(alignment: Alignment.centerLeft, child: _buildSectionTitle('Arus Kas Bulanan')),
                          const SizedBox(height: 16),
                          BarChartWidget(data: _getMockData().last6Months),
                          const SizedBox(height: 40),
                          Align(alignment: Alignment.centerLeft, child: _buildSectionTitle('Bulan Ini per Kategori')),
                          const SizedBox(height: 16),
                          ..._getMockData().topCategories.map((cat) => _buildCategoryRow(context, cat)),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  error: (err, stack) =>
                      SliverFillRemaining(child: _buildErrorState(err)),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildMainMetricCard(BuildContext context, dynamic data) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laba Rugi Bersih',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            formatIDR(data.monthly.income - data.monthly.expense),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _buildMiniMetric('Masuk', formatIDR(data.monthly.income),
                  const Color(0xFF10B981)),
              const SizedBox(width: 40),
              _buildMiniMetric('Keluar', formatIDR(data.monthly.expense),
                  const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2),
    );
  }

  Widget _buildCategoryRow(BuildContext context, dynamic cat) {
    // Determine the color from the hex string
    final categoryColor = cat.color != null
        ? Color(int.parse(cat.color.replaceFirst('#', '0xFF')))
        : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Text(
              cat.icon ?? '📝',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(formatIDR(cat.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (cat.percentage as num).toDouble() / 100,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text('Gagal memuat: ${err.toString().split('\n').first}',
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
