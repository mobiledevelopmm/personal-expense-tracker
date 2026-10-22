import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/transaction.dart';

class TransactionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _userTransactions() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to access transactions.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  Stream<List<ExpenseTransaction>> watchTransactions() {
    return _userTransactions()
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => ExpenseTransaction.fromMap(
          doc.id,
          doc.data(),
        ),
      )
          .toList(),
    );
  }


  Future<void> addTransaction(ExpenseTransaction transaction) async {
    try {
      final collection = _userTransactions();

      await collection
          .add(transaction.toMap())
          .timeout(const Duration(seconds: 15));
    } on FirebaseException catch (error) {
      throw Exception(
        'Firestore error (${error.code}): ${error.message ?? 'Unknown error'}',
      );
    } on TimeoutException {
      throw Exception(
        'Saving timed out. Please check your internet connection and Firebase settings.',
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _userTransactions().doc(id).delete();
  }
}