import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class ExpenseTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  const ExpenseTransaction({
    this.id = '',
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ExpenseTransaction.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    final rawDate = map['date'];

    return ExpenseTransaction(
      id: id,
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String? ?? 'Other',
      date: rawDate is Timestamp
          ? rawDate.toDate()
          : DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }
}