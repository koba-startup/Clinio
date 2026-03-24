import 'package:clinio/core/error/failure.dart';
import 'package:clinio/core/use_cases/use_case.dart';
import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await repository.signOut();
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Error al cerrar sesión'));
    }
  }
}