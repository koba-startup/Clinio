import 'package:clinio/core/error/failure.dart';
import 'package:clinio/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/network/network_info.dart';
import '../datasource/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<String?> get onAuthStateChanged => remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, void>> signIn(String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signIn(email, password);
        return const Right(null);
      } on FirebaseAuthException catch (e) {
        return Left(AuthFailure(_mapFirebaseError(e.code)));
      } catch (e) {
        return Left(AuthFailure('Error inesperado'));
      }
    } else {
      return const Left(ServerFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signUp(String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signUp(email, password);
        return const Right(null);
      } on FirebaseAuthException catch (e) {
        return Left(AuthFailure(_mapFirebaseError(e.code)));
      } catch (e) {
        return Left(AuthFailure('Error inesperado'));
      }
    } else {
      return const Left(ServerFailure('No hay conexión a internet'));
    }
  }
}

String _mapFirebaseError(String code) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos';
    case 'user-disabled':
      return 'Esta cuenta ha sido deshabilitada';
    case 'too-many-requests':
      return 'Demasiados intentos. Intenta más tarde';
    case 'email-already-in-use':
      return 'Este correo ya tiene una cuenta';
    case 'weak-password':
      return 'La contraseña debe tener al menos 6 caracteres';
    default:
      return 'Error de autenticación';
  }
}
