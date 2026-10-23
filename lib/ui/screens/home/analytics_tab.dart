
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/transaction.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/transaction/transaction_state.dart';

enum _AnalyticsPeriod { thisMonth, allTime }

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  _AnalyticsPeriod _period = _AnalyticsPeriod.thisMonth;

  static const Color _mint = Color(0xFFB9E4D0);
  static const Color _income = Color(0xFF168568);
  static const Color _expense = Color(0xFFC45B58);

  String _money(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return '\$$formatted';
  }

  List<ExpenseTransaction> _inPeriod(
      List<ExpenseTransaction> transactions,
      ) {
    if (_period == _AnalyticsPeriod.allTime) {
      return transactions;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    return transactions.where((transaction) {
      return !transaction.date.isBefore(start) &&
          transaction.date.isBefore(end);
    }).toList();
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
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Icon(
              Icons.insights_rounded,
              color: colors.primary,
            ),
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state.status == TransactionStatus.loading &&
              state.transactions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == TransactionStatus.failure &&
              state.transactions.isEmpty) {
            return _MessageState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load analytics',
              message:
              state.errorMessage ?? 'Please try again later.',
              color: mutedColor,
            );
          }

          final allTransactions = state.transactions;
          final filteredTransactions = _inPeriod(allTransactions);

          final incomeTransactions = filteredTransactions
              .where((t) => t.type == TransactionType.income)
              .toList();

          final expenses = filteredTransactions
              .where((t) => t.type == TransactionType.expense)
              .toList();

          final incomeTotal = incomeTransactions.fold<double>(
            0,
                (sum, transaction) => sum + transaction.amount,
          );

          final expenseTotal = expenses.fold<double>(
            0,
                (sum, transaction) => sum + transaction.amount,
          );

          final balance = incomeTotal - expenseTotal;

          final categoryTotals = <String, double>{};

          for (final transaction in expenses) {
            categoryTotals[transaction.category] =
                (categoryTotals[transaction.category] ?? 0) +
                    transaction.amount;
          }

          final categories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final recentExpenses = [...expenses]
            ..sort((a, b) => b.date.compareTo(a.date));

          final peakExpense = expenses.isEmpty
              ? 0.0
              : expenses
              .map((transaction) => transaction.amount)
              .reduce(math.max);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                'Your Money Insights',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Understand your income and spending habits.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 20),

              // Period selector
              _PeriodSelector(
                selected: _period,
                onChanged: (value) {
                  setState(() => _period = value);
                },
                emerald: colors.primary,
                surface: colors.surface,
                muted: mutedColor,
              ),
              const SizedBox(height: 18),

              // Net cash flow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [
                      Color(0xFF1B3042),
                      Color(0xFF123F3B),
                    ]
                        : const [
                      Color(0xFF115E59),
                      Color(0xFF0F766E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_period.label} net cash flow',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance < 0 ? '-' : ''}${_money(balance.abs())}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroAmount(
                            label: 'Income',
                            amount: _money(incomeTotal),
                            icon: Icons.south_west_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeroAmount(
                            label: 'Expenses',
                            amount: _money(expenseTotal),
                            icon: Icons.north_east_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Spending trend
              _SectionHeading(
                title: 'Spending trend',
                subtitle: _period.chartSubtitle,
                color: textColor,
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(
                child: expenses.isEmpty
                    ? _EmptyInside(
                  icon: Icons.bar_chart_rounded,
                  title: 'No spending data yet',
                  message:
                  'Add an expense to see your spending trend.',
                  color: mutedColor,
                )
                    : _SpendingChart(
                  transactions: expenses,
                  period: _period,
                  emerald: colors.primary,
                  mint: _mint,
                  text: textColor,
                  muted: mutedColor,
                ),
              ),
              const SizedBox(height: 24),

              // Spending by category
              _SectionHeading(
                title: 'Spending by category',
                subtitle: 'Where your money goes',
                color: textColor,
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(
                child: categories.isEmpty
                    ? _EmptyInside(
                  icon: Icons.donut_small_rounded,
                  title: 'No category data yet',
                  message:
                  'Add an expense to see your spending breakdown.',
                  color: mutedColor,
                )
                    : Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 55,
                              sections: categories
                                  .asMap()
                                  .entries
                                  .map((item) {
                                final entry = item.value;
                                final percentage = expenseTotal > 0
                                    ? entry.value /
                                    expenseTotal *
                                    100
                                    : 0.0;

                                return PieChartSectionData(
                                  color: _categoryColor(
                                    item.key,
                                    colors.primary,
                                  ),
                                  value: entry.value,
                                  title:
                                  '${percentage.round()}%',
                                  radius: 48,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  titlePositionPercentageOffset: 0.55,
                                );
                              }).toList(),
                              pieTouchData: PieTouchData(
                                enabled: true,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _money(expenseTotal),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(
                      color: colors.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category legend
                    ...categories.asMap().entries.map((item) {
                      final index = item.key;
                      final entry = item.value;

                      final percentage = expenseTotal > 0
                          ? entry.value / expenseTotal * 100
                          : 0.0;

                      final categoryColor = _categoryColor(
                        index,
                        colors.primary,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: categoryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _money(entry.value),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 43,
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
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

              // Recent expenses
              _SectionHeading(
                title: 'Recent expenses',
                subtitle: '${recentExpenses.length} transactions',
                color: textColor,
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(
                padding: EdgeInsets.zero,
                child: recentExpenses.isEmpty
                    ? _EmptyInside(
                  icon: Icons.receipt_long_rounded,
                  title: 'Nothing to show yet',
                  message: 'Expenses you add will appear here.',
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
                        child: Icon(
                          _categoryIcon(item.category),
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
              const SizedBox(height: 8),
              if (allTransactions.isEmpty)
                Text(
                  'Tip: add your first income or expense from the Home tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _categoryColor(int index, Color primary) {
    const palette = [
      Color(0xFF0F766E),
      Color(0xFF4D9B83),
      Color(0xFF7AAE91),
      Color(0xFFD49B55),
      Color(0xFF7B8FC7),
      Color(0xFFC45B58),
    ];

    return index < palette.length ? palette[index] : primary;
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'transportation':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'salary':
        return Icons.work_rounded;
      default:
        return Icons.wallet_rounded;
    }
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

extension on _AnalyticsPeriod {
  String get label {
    switch (this) {
      case _AnalyticsPeriod.thisMonth:
        return 'This Month';
      case _AnalyticsPeriod.allTime:
        return 'All Time';
    }
  }

  String get chartSubtitle {
    switch (this) {
      case _AnalyticsPeriod.thisMonth:
        return 'Daily expenses this month';
      case _AnalyticsPeriod.allTime:
        return 'Monthly spending history';
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.emerald,
    required this.surface,
    required this.muted,
  });

  final _AnalyticsPeriod selected;
  final ValueChanged<_AnalyticsPeriod> onChanged;
  final Color emerald;
  final Color surface;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: _AnalyticsPeriod.values.map((period) {
          final active = selected == period;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? emerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HeroAmount extends StatelessWidget {
  const _HeroAmount({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final String amount;
  final IconData icon;

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
          const SizedBox(width: 8),
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
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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

class _EmptyInside extends StatelessWidget {
  const _EmptyInside({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 10,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: color.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendingChart extends StatelessWidget {
  const _SpendingChart({
    required this.transactions,
    required this.period,
    required this.emerald,
    required this.mint,
    required this.text,
    required this.muted,
  });

  final List<ExpenseTransaction> transactions;
  final _AnalyticsPeriod period;
  final Color emerald;
  final Color mint;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<_ChartBucket> buckets;

    if (period == _AnalyticsPeriod.thisMonth) {
      final first = DateTime(now.year, now.month);
      final days = DateTime(now.year, now.month + 1, 0).day;

      buckets = List.generate(days, (index) {
        final day = first.add(Duration(days: index));
        return _ChartBucket('${day.day}', day);
      });
    } else {
      if (transactions.isEmpty) {
        buckets = [
          _ChartBucket(
            _month(now.month),
            DateTime(now.year, now.month),
          ),
        ];
      } else {
        final earliest = transactions
            .map((t) => DateTime(t.date.year, t.date.month))
            .reduce((a, b) => a.isBefore(b) ? a : b);

        final monthCount =
            (now.year - earliest.year) * 12 +
                now.month -
                earliest.month +
                1;

        buckets = List.generate(monthCount, (index) {
          final month = DateTime(
            earliest.year,
            earliest.month + index,
          );

          return _ChartBucket(
            '${_month(month.month)} ${month.year}',
            month,
          );
        });
      }
    }

    final values = List<double>.filled(buckets.length, 0);

    for (final transaction in transactions) {
      final index = period == _AnalyticsPeriod.thisMonth
          ? transaction.date.day - 1
          : (transaction.date.year - buckets.first.date.year) * 12 +
          transaction.date.month -
          buckets.first.date.month;

      if (index >= 0 && index < values.length) {
        values[index] += transaction.amount;
      }
    }

    final highest = values.fold<double>(
      0,
          (current, value) => math.max(current, value).toDouble(),
    );

    final visibleCount =
    period == _AnalyticsPeriod.thisMonth ? 15 : 12;

    final startIndex = buckets.length > visibleCount
        ? period == _AnalyticsPeriod.thisMonth
        ? (now.day - visibleCount ~/ 2)
        .clamp(0, buckets.length - visibleCount)
        : buckets.length - visibleCount
        : 0;

    final shownBuckets =
    buckets.skip(startIndex).take(visibleCount).toList();

    final shownValues =
    values.skip(startIndex).take(visibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
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
              period == _AnalyticsPeriod.thisMonth
                  ? 'Peak day'
                  : 'Peak month',
              style: TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 142,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(shownBuckets.length, (index) {
              final value = shownValues[index];
              final ratio = highest <= 0 ? 0.0 : value / highest;
              final bucketDate = shownBuckets[index].date;

              final isCurrent =
              period == _AnalyticsPeriod.thisMonth
                  ? bucketDate.day == now.day
                  : bucketDate.year == now.year &&
                  bucketDate.month == now.month;

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
                              color: isCurrent ? emerald : mint,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        period == _AnalyticsPeriod.thisMonth
                            ? shownBuckets[index].label
                            : _month(bucketDate.month),
                        style: TextStyle(
                          color: isCurrent ? emerald : muted,
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

  String _money(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return '\$$formatted';
  }

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _ChartBucket {
  const _ChartBucket(this.label, this.date);

  final String label;
  final DateTime date;
}
