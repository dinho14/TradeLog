import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(
    String email,
    String password, {
    required String fullName,
    String? displayName,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid;
    try {
      if (uid != null) {
        await saveUserProfile(
          uid: uid,
          email: email,
          fullName: fullName,
          displayName: displayName,
          phone: phone,
        );
      }
      return credential;
    } catch (e) {
      await credential.user?.delete();
      rethrow;
    }
  }

  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String fullName,
    String? displayName,
    String? phone,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'email': email,
      'fullName': fullName,
      'displayName': displayName ?? '',
      'phone': phone ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
