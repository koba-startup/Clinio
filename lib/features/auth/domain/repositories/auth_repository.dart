import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> signUp(String email, String password);

  Future<Either<Failure, void>> signIn(String email, String password);

  Future<Either<Failure, void>> signOut();

  Stream<String?> get onAuthStateChanged;
}
