
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

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to access transactions.');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> _userDocument(User user) =>
      _firestore.collection('users').doc(user.uid);

  CollectionReference<Map<String, dynamic>> _userTransactions() {
    final user = _requireUser();
    return _userDocument(user).collection('transactions');
  }

  // Make sure the parent users/{uid} document exists before saving a transaction.
  // Existing fields are preserved; this only creates the document if it is missing.
  Future<void> _ensureUserDocument(User user) async {
    final userDoc = _userDocument(user);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
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

  Future<void> addTransaction(
      ExpenseTransaction transaction,
      ) async {
    try {
      final user = _requireUser();
      await _ensureUserDocument(user);
      await _userTransactions()
          .add(transaction.toMap())
          .timeout(const Duration(seconds: 15));
    } on FirebaseException catch (error) {
      throw Exception(
        'Firestore error (${error.code}): '
            '${error.message ?? 'Unknown error'}',
      );
    } on TimeoutException {
      throw Exception(
        'Saving timed out. Please check your internet connection '
            'and Firebase settings.',
      );
    }
  }

  Future<void> updateTransaction(
      String id,
      ExpenseTransaction transaction,
      ) async {
    try {
      await _userTransactions()
          .doc(id)
          .update(transaction.toMap())
          .timeout(const Duration(seconds: 15));
    } on FirebaseException catch (error) {
      throw Exception(
        'Firestore error (${error.code}): '
            '${error.message ?? 'Unknown error'}',
      );
    } on TimeoutException {
      throw Exception(
        'Updating timed out. Please check your internet connection '
            'and Firebase settings.',
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _userTransactions().doc(id).delete();
  }
}