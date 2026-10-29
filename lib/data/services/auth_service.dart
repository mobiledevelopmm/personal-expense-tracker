
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final displayName = name.trim();
    final userEmail = email.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: userEmail,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.reload();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': displayName,
        'email': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return credential;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}