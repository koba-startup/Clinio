import 'package:clinio/core/error/failure.dart';
import 'package:clinio/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

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
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signOut();
        return const Right(null);
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> signUp(String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signUp(email, password);
        return const Right(null);
      } catch (e) {
        return Left(AuthFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No hay conexión a internet'));
    }
  }
}
