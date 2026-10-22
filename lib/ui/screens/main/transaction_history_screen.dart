
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/transaction.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/transaction/transaction_state.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  static const Color _income = Color(0xFF168568);
  static const Color _expense = Color(0xFFC45B58);
  static const Color _emeraldDark = Color(0xFF115E59);

  String _money(double amount) => '\$${amount.toStringAsFixed(2)}';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            final transactions = [...state.transactions]
              ..sort((a, b) => b.date.compareTo(a.date));

            final incomeTotal = transactions
                .where((t) => t.type == TransactionType.income)
                .fold<double>(0, (sum, t) => sum + t.amount);

            final expenseTotal = transactions
                .where((t) => t.type == TransactionType.expense)
                .fold<double>(0, (sum, t) => sum + t.amount);

            if (state.status == TransactionStatus.loading &&
                transactions.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.status == TransactionStatus.failure &&
                transactions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: _expense,
                      ),
                      const SizedBox(height: 12),
                      const Text('Could not load transaction history'),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ??
                            'Please try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
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

            if (transactions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your income and expenses will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF101D2C),
                        Color(0xFF1B3042),
                        _emeraldDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALL TRANSACTIONS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${transactions.length} transactions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              title: 'Total Income',
                              amount: _money(incomeTotal),
                              color: const Color(0xFFB9E4D0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryItem(
                              title: 'Total Expenses',
                              amount: _money(expenseTotal),
                              color: const Color(0xFFFFC4C0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'All Records',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colors.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < transactions.length; i++) ...[
                        _TransactionTile(
                          transaction: transactions[i],
                          money: _money,
                          formatDate: _formatDate,
                        ),
                        if (i < transactions.length - 1)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colors.outlineVariant,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.money,
    required this.formatDate,
  });

  final ExpenseTransaction transaction;
  final String Function(double) money;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome
        ? const Color(0xFF168568)
        : const Color(0xFFC45B58);
    final background = isIncome
        ? const Color(0xFFE3F3EB)
        : const Color(0xFFFAECEA);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          isIncome
              ? Icons.south_west_rounded
              : Icons.north_east_rounded,
          color: color,
        ),
      ),
      title: Text(
        transaction.category,
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          transaction.note.isEmpty
              ? formatDate(transaction.date)
              : '${transaction.note} · ${formatDate(transaction.date)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${money(transaction.amount)}',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
