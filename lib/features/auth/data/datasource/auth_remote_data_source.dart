import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDataSource {
  Future<void> signUp(String email, String password);

  Future<void> signIn(String email, String password);

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Stream<String?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl(this.firebaseAuth);

  @override
  // TODO: implement authStateChanges
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
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
