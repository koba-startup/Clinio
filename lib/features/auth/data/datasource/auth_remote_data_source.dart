import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> signUp(String email, String password);

  Future<void> signIn(String email, String password);

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Stream<String?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore; // ← agregar

  AuthRemoteDataSourceImpl(this.firebaseAuth, this.firestore); // ← agregar

  @override
  Stream<String?> get authStateChanges =>
      firebaseAuth.authStateChanges().map((user) => user?.uid);

  @override
  Future<void> signIn(String email, String password) async {
    await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() => firebaseAuth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signUp(String email, String password) async {
    // 1. Crear usuario en Firebase Auth
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Crear documento en Firestore con los datos iniciales
    final user = UserModel(
      id: credential.user!.uid,
      email: email,
      plan: 'free',
    );

    await firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(user.toFirestore());
  }
}
