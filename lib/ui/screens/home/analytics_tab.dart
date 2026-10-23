
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/transaction.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/transaction/transaction_state.dart';

enum _AnalyticsPeriod { month, year, allTime }

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  _AnalyticsPeriod _period = _AnalyticsPeriod.month;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedYear = DateTime.now().year;

  static const Color _mint = Color(0xFFB9E4D0);
  static const Color _income = Color(0xFF168568);
  static const Color _expense = Color(0xFFC45B58);

  String _money(double amount) {
    final formatted = amount.abs().toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '${amount < 0 ? '-' : ''}\$$formatted';
  }

  List<ExpenseTransaction> _inPeriod(
      List<ExpenseTransaction> transactions,
      ) {
    switch (_period) {
      case _AnalyticsPeriod.month:
        return transactions.where((t) =>
        t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month).toList();

      case _AnalyticsPeriod.year:
        return transactions
            .where((t) => t.date.year == _selectedYear)
            .toList();

      case _AnalyticsPeriod.allTime:
        return transactions;
    }
  }

  String get _periodLabel {
    switch (_period) {
      case _AnalyticsPeriod.month:
        return '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}';
      case _AnalyticsPeriod.year:
        return '$_selectedYear';
      case _AnalyticsPeriod.allTime:
        return 'All Time';
    }
  }

  String _monthName(int month) => const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ][month - 1];

  void _changeMonth(int amount) {
    final now = DateTime.now();
    final next = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + amount,
    );

    if (next.year < 2000 ||
        next.year > now.year ||
        (next.year == now.year && next.month > now.month)) {
      return;
    }

    setState(() => _selectedMonth = next);
  }

  void _changeYear(int amount) {
    final next = _selectedYear + amount;
    if (next < 2000 || next > DateTime.now().year) return;
    setState(() => _selectedYear = next);
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();

    if (_period == _AnalyticsPeriod.month) {
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
    } else if (_period == _AnalyticsPeriod.year) {
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = colors.onSurface;
    final mutedColor = colors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Icon(Icons.insights_rounded, color: colors.primary),
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
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
                child: Text(
                  state.errorMessage ?? 'Could not load analytics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor),
                ),
              ),
            );
          }

          final filtered = _inPeriod(state.transactions);

          final incomes = filtered
              .where((t) => t.type == TransactionType.income)
              .toList();

          final expenses = filtered
              .where((t) => t.type == TransactionType.expense)
              .toList();

          final incomeTotal =
          incomes.fold<double>(0, (sum, t) => sum + t.amount);

          final expenseTotal =
          expenses.fold<double>(0, (sum, t) => sum + t.amount);

          final netBalance = incomeTotal - expenseTotal;

          final categoryTotals = <String, double>{};
          for (final t in expenses) {
            categoryTotals[t.category] =
                (categoryTotals[t.category] ?? 0) + t.amount;
          }

          final categories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final recentExpenses = [...expenses]
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                'Your Money Overview',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Understand where your money goes.',
                style: TextStyle(color: mutedColor),
              ),
              const SizedBox(height: 20),

              // Three period options
              _PeriodSelector(
                selected: _period,
                onChanged: (value) {
                  setState(() {
                    _period = value;
                    final now = DateTime.now();
                    if (_selectedYear > now.year) {
                      _selectedYear = now.year;
                    }
                  });
                },
                primary: colors.primary,
                surface: colors.surface,
                muted: mutedColor,
                border: colors.outlineVariant,
              ),
              const SizedBox(height: 12),

              if (_period != _AnalyticsPeriod.allTime)
                _PeriodNavigator(
                  label: _periodLabel,
                  onPrevious: () {
                    if (_period == _AnalyticsPeriod.month) {
                      _changeMonth(-1);
                    } else {
                      _changeYear(-1);
                    }
                  },
                  onNext: () {
                    if (_period == _AnalyticsPeriod.month) {
                      _changeMonth(1);
                    } else {
                      _changeYear(1);
                    }
                  },
                  onPick: _pickPeriod,
                  canGoNext: _period == _AnalyticsPeriod.month
                      ? _selectedMonth.year < DateTime.now().year ||
                      (_selectedMonth.year == DateTime.now().year &&
                          _selectedMonth.month < DateTime.now().month)
                      : _selectedYear < DateTime.now().year,
                  surface: colors.surface,
                  border: colors.outlineVariant,
                  text: textColor,
                  muted: mutedColor,
                ),

              const SizedBox(height: 18),

              // Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1B3042), Color(0xFF123F3B)]
                        : const [Color(0xFF115E59), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_periodLabel net balance',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _money(netBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _AmountTile(
                            label: 'Income',
                            amount: _money(incomeTotal),
                            icon: Icons.south_west_rounded,
                            color: _income,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AmountTile(
                            label: 'Expenses',
                            amount: _money(expenseTotal),
                            icon: Icons.north_east_rounded,
                            color: _expense,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _SectionHeading(
                title: 'Spending Trend',
                subtitle: _period == _AnalyticsPeriod.month
                    ? 'Daily spending · $_periodLabel'
                    : _period == _AnalyticsPeriod.year
                    ? 'Monthly spending · $_selectedYear'
                    : 'Monthly spending history',
                color: textColor,
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(
                child: expenses.isEmpty
                    ? _EmptyAnalytics(
                  title: 'No spending data',
                  message: 'No expenses recorded for $_periodLabel.',
                  color: mutedColor,
                )
                    : _SpendingChart(
                  transactions: expenses,
                  period: _period,
                  selectedMonth: _selectedMonth,
                  selectedYear: _selectedYear,
                  primary: colors.primary,
                  mint: _mint,
                  text: textColor,
                  muted: mutedColor,
                ),
              ),

              const SizedBox(height: 24),
              _SectionHeading(
                title: 'Expense Breakdown',
                subtitle: 'Spending by category · $_periodLabel',
                color: textColor,
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(
                child: categories.isEmpty
                    ? _EmptyAnalytics(
                  title: 'No category data',
                  message: 'Expenses will appear here by category.',
                  color: mutedColor,
                )
                    : Column(
                  children: [
                    SizedBox(
                      height: 230,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 53,
                              sections: categories
                                  .asMap()
                                  .entries
                                  .map((item) {
                                final entry = item.value;
                                final percent = expenseTotal > 0
                                    ? entry.value / expenseTotal * 100
                                    : 0.0;

                                return PieChartSectionData(
                                  color: _categoryColor(item.key),
                                  value: entry.value,
                                  title: '${percent.round()}%',
                                  radius: 48,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total Expenses',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _money(expenseTotal),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: colors.outlineVariant),
                    const SizedBox(height: 12),
                    ...categories.asMap().entries.map((item) {
                      final entry = item.value;
                      final percent = expenseTotal > 0
                          ? entry.value / expenseTotal * 100
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: _categoryColor(item.key),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _money(entry.value),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 48,
                              child: Text(
                                '${percent.toStringAsFixed(1)}%',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _SectionHeading(
                title: 'Recent Expenses',
                subtitle:
                '${recentExpenses.length} transactions · $_periodLabel',
                color: textColor,
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(
                padding: EdgeInsets.zero,
                child: recentExpenses.isEmpty
                    ? _EmptyAnalytics(
                  title: 'Nothing to show yet',
                  message: 'Expenses for this period appear here.',
                  color: mutedColor,
                )
                    : Column(
                  children: recentExpenses.take(5).map((item) {
                    return ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _expense.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: _expense,
                        ),
                      ),
                      title: Text(
                        item.category,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        item.note.isNotEmpty
                            ? item.note
                            : _dateLabel(item.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        '-${_money(item.amount)}',
                        style: const TextStyle(
                          color: _expense,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _categoryColor(int index) {
    const palette = [
      Color(0xFF0F766E),
      Color(0xFF4D9B83),
      Color(0xFF7AAE91),
      Color(0xFFD49B55),
      Color(0xFF7B8FC7),
      Color(0xFFC45B58),
      Color(0xFF9274B8),
      Color(0xFF4F91A8),
    ];
    return palette[index % palette.length];
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
}


class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.primary,
    required this.surface,
    required this.muted,
    required this.border,
  });

  final _AnalyticsPeriod selected;
  final ValueChanged<_AnalyticsPeriod> onChanged;
  final Color primary;
  final Color surface;
  final Color muted;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          _buildOption(_AnalyticsPeriod.month, 'Month'),
          _buildOption(_AnalyticsPeriod.year, 'Year'),
          _buildOption(_AnalyticsPeriod.allTime, 'All Time'),
        ],
      ),
    );
  }

  Widget _buildOption(_AnalyticsPeriod period, String label) {
    final active = selected == period;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: active ? Colors.white : muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    required this.canGoNext,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;
  final bool canGoNext;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            tooltip: 'Previous period',
            icon: Icon(Icons.chevron_left_rounded, color: muted),
          ),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded, color: text, size: 19),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
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
            onPressed: canGoNext ? onNext : null,
            tooltip: 'Next period',
            icon: Icon(
              Icons.chevron_right_rounded,
              color: canGoNext ? muted : muted.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            subtitle,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: child,
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics({
    required this.title,
    required this.message,
    required this.color,
  });

  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 10),
      child: Column(
        children: [
          Icon(Icons.insert_chart_outlined_rounded, size: 36, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SpendingChart extends StatelessWidget {
  const _SpendingChart({
    required this.transactions,
    required this.period,
    required this.selectedMonth,
    required this.selectedYear,
    required this.primary,
    required this.mint,
    required this.text,
    required this.muted,
  });

  final List<ExpenseTransaction> transactions;
  final _AnalyticsPeriod period;
  final DateTime selectedMonth;
  final int selectedYear;
  final Color primary;
  final Color mint;
  final Color text;
  final Color muted;

  String _money(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    late final List<DateTime> bucketDates;
    late final List<String> labels;

    if (period == _AnalyticsPeriod.month) {
      final days = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
      ).day;

      bucketDates = List.generate(
        days,
            (i) => DateTime(selectedMonth.year, selectedMonth.month, i + 1),
      );
      labels = bucketDates.map((d) => '${d.day}').toList();
    } else if (period == _AnalyticsPeriod.year) {
      bucketDates = List.generate(
        12,
            (i) => DateTime(selectedYear, i + 1),
      );
      labels = bucketDates.map((d) => _month(d.month)).toList();
    } else {
      if (transactions.isEmpty) {
        bucketDates = [DateTime(now.year, now.month)];
      } else {
        final earliest = transactions
            .map((t) => DateTime(t.date.year, t.date.month))
            .reduce((a, b) => a.isBefore(b) ? a : b);

        final count = (now.year - earliest.year) * 12 +
            now.month -
            earliest.month +
            1;

        bucketDates = List.generate(
          count,
              (i) => DateTime(earliest.year, earliest.month + i),
        );
      }
      labels = bucketDates.map((d) => _month(d.month)).toList();
    }

    final values = List<double>.filled(bucketDates.length, 0);

    for (final transaction in transactions) {
      final index = period == _AnalyticsPeriod.month
          ? transaction.date.day - 1
          : period == _AnalyticsPeriod.year
          ? transaction.date.month - 1
          : (transaction.date.year - bucketDates.first.year) * 12 +
          transaction.date.month -
          bucketDates.first.month;

      if (index >= 0 && index < values.length) {
        values[index] += transaction.amount;
      }
    }

    final highest = values.fold<double>(
      0,
          (current, value) => math.max(current, value).toDouble(),
    );

    const countToShow = 12;

    final startIndex = bucketDates.length > countToShow
        ? period == _AnalyticsPeriod.month
        ? (now.day - countToShow ~/ 2)
        .clamp(0, bucketDates.length - countToShow)
        : bucketDates.length - countToShow
        : 0;

    final shownLabels = labels.skip(startIndex).take(countToShow).toList();
    final shownValues = values.skip(startIndex).take(countToShow).toList();
    final shownDates =
    bucketDates.skip(startIndex).take(countToShow).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _money(highest),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              period == _AnalyticsPeriod.month ? 'Peak day' : 'Peak month',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 142,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(shownDates.length, (index) {
              final date = shownDates[index];
              final value = shownValues[index];
              final ratio = highest == 0 ? 0.0 : value / highest;

              final isCurrent = period == _AnalyticsPeriod.month
                  ? date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day
                  : date.year == now.year && date.month == now.month;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            height: value == 0
                                ? 4
                                : math.max(7, 94 * ratio).toDouble(),
                            decoration: BoxDecoration(
                              color: isCurrent ? primary : mint,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shownLabels[index],
                        style: TextStyle(
                          color: isCurrent ? primary : muted,
                          fontSize: 9,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _month(int month) => const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][month - 1];
}
