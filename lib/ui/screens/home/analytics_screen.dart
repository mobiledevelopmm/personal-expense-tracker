import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/transaction.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/transaction/transaction_state.dart';

enum _Period { month, year, allTime }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Period _period = _Period.month;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedYear = DateTime.now().year;

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

  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _text => Theme.of(context).colorScheme.onSurface;
  Color get _muted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).colorScheme.outlineVariant;
  Color get _primary => Theme.of(context).colorScheme.primary;

  String _money(double amount) {
    final fixed = amount.abs().toStringAsFixed(2).split('.');
    final whole = fixed[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '${amount < 0 ? '-' : ''}\$$whole.${fixed[1]}';
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  String get _periodLabel {
    switch (_period) {
      case _Period.month:
        return '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}';
      case _Period.year:
        return '$_selectedYear';
      case _Period.allTime:
        return 'All Time';
    }
  }

  List<ExpenseTransaction> _filterTransactions(
      List<ExpenseTransaction> transactions,
      ) {
    switch (_period) {
      case _Period.month:
        return transactions
            .where(
              (t) =>
          t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month,
        )
            .toList();

      case _Period.year:
        return transactions.where((t) => t.date.year == _selectedYear).toList();

      case _Period.allTime:
        return transactions;
    }
  }

  void _previousPeriod() {
    setState(() {
      if (_period == _Period.month) {
        _selectedMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month - 1,
        );
      } else if (_period == _Period.year && _selectedYear > 2000) {
        _selectedYear--;
      }
    });
  }

  void _nextPeriod() {
    final now = DateTime.now();

    setState(() {
      if (_period == _Period.month) {
        final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
        if (!next.isAfter(DateTime(now.year, now.month))) {
          _selectedMonth = next;
        }
      } else if (_period == _Period.year && _selectedYear < now.year) {
        _selectedYear++;
      }
    });
  }

  bool get _canGoNext {
    final now = DateTime.now();
    if (_period == _Period.month) {
      return _selectedMonth.year < now.year ||
          (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
    }
    if (_period == _Period.year) {
      return _selectedYear < now.year;
    }
    return false;
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();

    if (_period == _Period.month) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedMonth,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDatePickerMode: DatePickerMode.year,
        helpText: 'Select month',
      );

      if (picked != null && mounted) {
        setState(() {
          _selectedMonth = DateTime(picked.year, picked.month);
        });
      }
    } else if (_period == _Period.year) {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(_selectedYear, 1, 1),
        firstDate: DateTime(2000),
        lastDate: now,
        initialDatePickerMode: DatePickerMode.year,
        helpText: 'Select year',
      );

      if (picked != null && mounted) {
        setState(() => _selectedYear = picked.year);
      }
    }
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

            final transactions = _filterTransactions(state.transactions);

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

            // Build income totals separately so expense and income charts
            // never mix transaction types.
            final incomeCategoryTotals = <String, double>{};

            for (final transaction in transactions) {
              if (transaction.type == TransactionType.income) {
                incomeCategoryTotals.update(
                  transaction.category,
                      (value) => value + transaction.amount,
                  ifAbsent: () => transaction.amount,
                );
              }
            }

            final sortedIncomeCategories =
            incomeCategoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final totalIncomeByCategory =
            sortedIncomeCategories.fold<double>(
              0,
                  (sum, entry) => sum + entry.value,
            );

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TransactionCubit>().listenToTransactions();
                await Future<void>.delayed(const Duration(milliseconds: 500));
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

                  // Month / Year / All Time selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        _periodButton('Month', _Period.month),
                        _periodButton('Year', _Period.year),
                        _periodButton('All Time', _Period.allTime),
                      ],
                    ),
                  ),

                  if (_period != _Period.allTime) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _previousPeriod,
                            icon: Icon(
                              Icons.chevron_left_rounded,
                              color: _muted,
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _pickPeriod,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18,
                                      color: _text,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _periodLabel,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _text,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _canGoNext ? _nextPeriod : null,
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: _canGoNext ? _muted : _border,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                            color: _primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Net Balance',
                                style: TextStyle(color: _muted),
                              ),
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
                    'Spending by category · $_periodLabel',
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
                            'No expense data for $_periodLabel',
                            textAlign: TextAlign.center,
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
                                for (
                                int i = 0;
                                i < sortedCategories.length;
                                i++
                                )
                                  PieChartSectionData(
                                    value: sortedCategories[i].value,
                                    color:
                                    _chartColors[i %
                                        _chartColors.length],
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
                          style: TextStyle(color: _muted, fontSize: 12),
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
                        for (
                        int i = 0;
                        i < sortedCategories.length;
                        i++
                        ) ...[
                          _categoryRow(
                            name: sortedCategories[i].key,
                            amount: sortedCategories[i].value,
                            total: totalExpense,
                            color: _chartColors[i % _chartColors.length],
                          ),
                          if (i < sortedCategories.length - 1)
                            Divider(height: 20, color: _border),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Income breakdown uses the same selected Month / Year /
                  // All Time period as the expense breakdown above.
                  Text(
                    'Income Breakdown',
                    style: TextStyle(
                      color: _text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Income by category · $_periodLabel',
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
                    child: totalIncomeByCategory <= 0
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
                            'No income data for $_periodLabel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Add an income to see your chart.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                            ),
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
                                for (
                                int i = 0;
                                i < sortedIncomeCategories.length;
                                i++
                                )
                                  PieChartSectionData(
                                    value:
                                    sortedIncomeCategories[i].value,
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
                          'Total Income',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _money(totalIncomeByCategory),
                          style: TextStyle(
                            color: _text,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 22),
                        for (
                        int i = 0;
                        i < sortedIncomeCategories.length;
                        i++
                        ) ...[
                          _categoryRow(
                            name: sortedIncomeCategories[i].key,
                            amount: sortedIncomeCategories[i].value,
                            total: totalIncomeByCategory,
                            color: _chartColors[
                            i % _chartColors.length],
                          ),
                          if (i < sortedIncomeCategories.length - 1)
                            Divider(height: 20, color: _border),
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

  Widget _periodButton(String label, _Period value) {
    final selected = _period == value;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _period = value),
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(color: _text, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
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