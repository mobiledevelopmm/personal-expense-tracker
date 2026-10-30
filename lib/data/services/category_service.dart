
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  CollectionReference<Map<String, dynamic>> _categoriesRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('categories');
  }

  Future<void> initializeDefaultCategories() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final categoriesRef = _categoriesRef(user.uid);

    // Add defaults without deleting custom categories.
    await categoriesRef.doc('income_categories').set({
      'type': 'income',
      'categories': FieldValue.arrayUnion(incomeCategories),
    }, SetOptions(merge: true));

    await categoriesRef.doc('expense_categories').set({
      'type': 'expense',
      'categories': FieldValue.arrayUnion(expenseCategories),
    }, SetOptions(merge: true));
  }

  Future<List<String>> getCategories(String type) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final docId = type.toLowerCase() == 'income'
        ? 'income_categories'
        : 'expense_categories';

    final snapshot = await _categoriesRef(user.uid)
        .doc(docId)
        .get();

    final values = snapshot.data()?['categories'];

    if (values is! List) return [];

    return values.map((value) => value.toString()).toList();
  }

  Future<void> addCategory({
    required String name,
    required String type,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final categoryName = name.trim();

    if (categoryName.isEmpty) {
      throw Exception('Category name cannot be empty.');
    }

    final docId = type.toLowerCase() == 'income'
        ? 'income_categories'
        : 'expense_categories';

    await _categoriesRef(user.uid).doc(docId).set({
      'type': type.toLowerCase(),
      'categories': FieldValue.arrayUnion([categoryName]),
    }, SetOptions(merge: true));
  }

  Stream<List<String>> watchCategories(String type) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    final docId = type.toLowerCase() == 'income'
        ? 'income_categories'
        : 'expense_categories';

    return _categoriesRef(user.uid)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      final values = snapshot.data()?['categories'];

      if (values is! List) return <String>[];

      return values.map((value) => value.toString()).toList();
    });
  }
}
