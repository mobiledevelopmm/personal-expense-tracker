import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> incomeCategories = [
    'Salary',
    'Business',
    'Investment',
    'Gift',
    'Other',
  ];

  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Education',
    'Entertainment',
    'Other',
  ];

  Future<void> initializeDefaultCategories() async {
    final user = _auth.currentUser;

    debugPrint('========== CATEGORY INITIALIZATION ==========');
    debugPrint('Firebase Project: ${_firestore.app.options.projectId}');
    debugPrint('Current User ID: ${user?.uid}');

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final categoriesRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories');

    await categoriesRef.doc('income_categories').set({
      'type': 'income',
      'categories': incomeCategories,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('Income categories write completed.');

    await categoriesRef.doc('expense_categories').set({
      'type': 'expense',
      'categories': expenseCategories,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('Expense categories write completed.');

    final result = await categoriesRef.get();

    debugPrint('Categories collection document count: ${result.docs.length}');
    for (final doc in result.docs) {
      debugPrint('Saved document: ${doc.id}');
    }

    debugPrint('========== CATEGORY INITIALIZATION DONE ==========');
  }

  Stream<List<String>> watchCategories(String type) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    final docId = type.toLowerCase() == 'income'
        ? 'income_categories'
        : 'expense_categories';

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return <String>[];

      final values = snapshot.data()?['categories'];

      if (values is! List) return <String>[];

      return values.map((value) => value.toString()).toList();
    });
  }
}
