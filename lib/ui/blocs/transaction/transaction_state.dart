import '../../../models/transaction.dart';

enum TransactionStatus {
  initial,
  loading,
  success,
  failure,
}

class TransactionState {
  final TransactionStatus status;
  final List<ExpenseTransaction> transactions;
  final String? errorMessage;

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.errorMessage,
  });

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;

  TransactionState copyWith({
    TransactionStatus? status,
    List<ExpenseTransaction>? transactions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}