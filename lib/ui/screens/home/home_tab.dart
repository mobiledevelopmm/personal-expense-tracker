
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/transaction.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/transaction/transaction_state.dart';
import '../main/transaction_history_screen.dart';
import 'add_transaction_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _hideBalance = false;

  static const Color _navy = Color(0xFF101D2C);
  static const Color _navyLight = Color(0xFF1B3042);
  static const Color _emerald = Color(0xFF0F766E);
  static const Color _emeraldDark = Color(0xFF115E59);
  static const Color _mint = Color(0xFFB9E4D0);
  static const Color _income = Color(0xFF168568);
  static const Color _expense = Color(0xFFC45B58);

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _muted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).colorScheme.outlineVariant;

  Color get _mintLight => _isDark
      ? const Color(0xFF203A35)
      : const Color(0xFFE3F3EB);

  Color get _expenseLight => _isDark
      ? const Color(0xFF422B2B)
      : const Color(0xFFFAECEA);

  Future<void> _openAddTransaction(TransactionType type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TransactionCubit>(),
          child: AddTransactionScreen(initialType: type),
        ),
      ),
    );
  }

  void _openTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TransactionCubit>(),
          child: const TransactionHistoryScreen(),
        ),
      ),
    );
  }

  String _money(double amount) {
    // Format amounts with thousands separators, e.g. $1,250,000.00.
    final fixedAmount = amount.abs().toStringAsFixed(2);
    final parts = fixedAmount.split('.');
    final wholeNumber = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );
    final sign = amount < 0 ? '-' : '';

    return '$sign\$$wholeNumber.${parts[1]}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: _mint,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY EXPENSES',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Personal finance',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications coming soon.'),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 22,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _surface,
                foregroundColor: _textPrimary,
                side: BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                fixedSize: const Size(46, 46),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            final transactions = state.transactions;

            final monthlyTransactions = transactions
                .where((t) => _isCurrentMonth(t.date))
                .toList();

            final monthlyIncome = monthlyTransactions
                .where((t) => t.type == TransactionType.income)
                .fold<double>(0, (sum, t) => sum + t.amount);

            final monthlyExpenses = monthlyTransactions
                .where((t) => t.type == TransactionType.expense)
                .fold<double>(0, (sum, t) => sum + t.amount);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcome(),
                  const SizedBox(height: 24),
                  _buildBalanceCard(state.balance),
                  const SizedBox(height: 28),
                  _buildQuickActions(),
                  const SizedBox(height: 30),
                  _buildSectionHeader(
                    title: 'This Month',
                    subtitle: 'Your financial overview',
                  ),
                  const SizedBox(height: 16),
                  _buildMonthlySummary(
                    monthlyIncome,
                    monthlyExpenses,
                  ),
                  const SizedBox(height: 30),
                  _buildSectionHeader(
                    title: 'Recent Transactions',
                    subtitle: 'Keep track of your money',
                    actionLabel: 'View all',
                    onAction: _openTransactionHistory,
                  ),
                  const SizedBox(height: 16),
                  if (state.status == TransactionStatus.loading &&
                      transactions.isEmpty)
                    _buildLoading()
                  else if (state.status == TransactionStatus.failure &&
                      transactions.isEmpty)
                    _buildError(state.errorMessage)
                  else if (transactions.isEmpty)
                      _buildEmptyTransactions()
                    else
                      _buildRecentTransactions(transactions),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _emerald,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'YOUR FINANCIAL SPACE',
              style: TextStyle(
                color: _emeraldDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome back!',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Make every dollar count.',
          style: TextStyle(
            color: _muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _navyLight, _emeraldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _mint.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.13),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -65,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _mint.withValues(alpha: 0.10),
                  width: 24,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'TOTAL BALANCE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(
                          () => _hideBalance = !_hideBalance,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        _hideBalance
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _mint,
                        size: 19,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _mint,
                    size: 27,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  _hideBalance ? '••••••' : _money(balance),
                  key: ValueKey('$_hideBalance-$balance'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 39,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: _mint,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Your money, your overview.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Add Income',
            subtitle: 'Money in',
            icon: Icons.south_west_rounded,
            color: _income,
            background: _mintLight,
            onTap: () => _openAddTransaction(TransactionType.income),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionCard(
            title: 'Add Expense',
            subtitle: 'Money out',
            icon: Icons.north_east_rounded,
            color: _expense,
            background: _expenseLight,
            onTap: () => _openAddTransaction(TransactionType.expense),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor:
              _isDark ? const Color(0xFF7DD3C7) : _emeraldDark,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.chevron_right_rounded, size: 19),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMonthlySummary(double income, double expenses) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Income',
            amount: _money(income),
            icon: Icons.trending_up_rounded,
            color: _income,
            background: _mintLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildSummaryCard(
            title: 'Expenses',
            amount: _money(expenses),
            icon: Icons.trending_down_rounded,
            color: _expense,
            background: _expenseLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'This month',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<ExpenseTransaction> transactions) {
    final recent = transactions.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < recent.length; i++) ...[
            _buildTransactionTile(recent[i]),
            if (i < recent.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: _border,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionTile(ExpenseTransaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? _income : _expense;
    final background = isIncome ? _mintLight : _expenseLight;

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
          isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: color,
          size: 21,
        ),
      ),
      title: Text(
        transaction.category,
        style: TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        transaction.note.isEmpty
            ? _formatDate(transaction.date)
            : '${transaction.note} · ${_formatDate(transaction.date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: _muted, fontSize: 11),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${_money(transaction.amount)}',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(String? message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 35, color: _expense),
          const SizedBox(height: 10),
          Text(
            'Could not load transactions',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ?? 'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () =>
                context.read<TransactionCubit>().listenToTransactions(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _mintLight,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: _isDark ? const Color(0xFF7DD3C7) : _emeraldDark,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your income and expenses will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () =>
                _openAddTransaction(TransactionType.expense),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Add your first transaction'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
              _isDark ? const Color(0xFF7DD3C7) : _emeraldDark,
              side: BorderSide(
                color: _isDark
                    ? const Color(0xFF4D9B8F)
                    : _emerald,
              ),
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}