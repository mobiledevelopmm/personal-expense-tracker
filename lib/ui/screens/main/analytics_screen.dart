
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/transaction.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/transaction/transaction_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _thisMonth = true;

  static const List<Color> _chartColors = [
    Color(0xFF0F766E),
    Color(0xFF34A78B),
    Color(0xFF8BCDB2),
    Color(0xFFE5B567),
    Color(0xFF6489C7),
    Color(0xFFB58AD4),
    Color(0xFFC45B58),
    Color(0xFF78A8B8),
    Color(0xFF8C9A72),
    Color(0xFFD58D65),
  ];

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _text => Theme.of(context).colorScheme.onSurface;
  Color get _muted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).colorScheme.outlineVariant;

  String _money(double amount) {
    final fixed = amount.abs().toStringAsFixed(2).split('.');
    final whole = fixed[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '\$$whole.${fixed[1]}';
  }

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _background,
        foregroundColor: _text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            if (state.status == TransactionStatus.loading &&
                state.transactions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == TransactionStatus.failure &&
                state.transactions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 42),
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage ?? 'Could not load transactions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context
                            .read<TransactionCubit>()
                            .listenToTransactions(),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final transactions = state.transactions.where((transaction) {
              return !_thisMonth || _isCurrentMonth(transaction.date);
            }).toList();

            final income = transactions
                .where((t) => t.type == TransactionType.income)
                .fold<double>(0, (sum, t) => sum + t.amount);

            final expenses = transactions
                .where((t) => t.type == TransactionType.expense)
                .fold<double>(0, (sum, t) => sum + t.amount);

            final categoryTotals = <String, double>{};

            for (final transaction in transactions) {
              if (transaction.type == TransactionType.expense) {
                categoryTotals.update(
                  transaction.category,
                      (value) => value + transaction.amount,
                  ifAbsent: () => transaction.amount,
                );
              }
            }

            final sortedCategories = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final totalExpense = sortedCategories.fold<double>(
              0,
                  (sum, entry) => sum + entry.value,
            );

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TransactionCubit>().listenToTransactions();
                await Future<void>.delayed(
                  const Duration(milliseconds: 500),
                );
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    'Your Money Overview',
                    style: TextStyle(
                      color: _text,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Understand where your money goes.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 22),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('This Month'),
                        icon: Icon(Icons.calendar_month_rounded),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('All Time'),
                        icon: Icon(Icons.all_inclusive_rounded),
                      ),
                    ],
                    selected: {_thisMonth},
                    onSelectionChanged: (value) {
                      setState(() => _thisMonth = value.first);
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          title: 'Income',
                          amount: income,
                          icon: Icons.south_west_rounded,
                          color: const Color(0xFF168568),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          title: 'Expenses',
                          amount: expenses,
                          icon: Icons.north_east_rounded,
                          color: const Color(0xFFC45B58),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Net Balance', style: TextStyle(color: _muted)),
                              const SizedBox(height: 5),
                              Text(
                                _money(income - expenses),
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Expense Breakdown',
                    style: TextStyle(
                      color: _text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Spending by category',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _border),
                    ),
                    child: totalExpense <= 0
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 54,
                            color: _muted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No expense data yet',
                            style: TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Add an expense to see your chart.',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                        : Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 58,
                              startDegreeOffset: -90,
                              sections: [
                                for (int i = 0;
                                i < sortedCategories.length;
                                i++)
                                  PieChartSectionData(
                                    value: sortedCategories[i].value,
                                    color: _chartColors[
                                    i % _chartColors.length],
                                    radius: 27,
                                    showTitle: false,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Total Expenses',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _money(totalExpense),
                          style: TextStyle(
                            color: _text,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 22),
                        for (int i = 0;
                        i < sortedCategories.length;
                        i++) ...[
                          _categoryRow(
                            name: sortedCategories[i].key,
                            amount: sortedCategories[i].value,
                            total: totalExpense,
                            color: _chartColors[
                            i % _chartColors.length],
                          ),
                          if (i < sortedCategories.length - 1)
                            Divider(
                              height: 20,
                              color: _border,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 13),
          Text(title, style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(amount),
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow({
    required String name,
    required double amount,
    required double total,
    required Color color,
  }) {
    final percentage = total > 0 ? amount / total * 100 : 0.0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 5,
                  backgroundColor: _border.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _money(amount),
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
