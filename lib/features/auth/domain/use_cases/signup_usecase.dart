import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/use_cases/use_case.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<void, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);
  @override
  Future<Either<Failure, void>> call(SignUpParams params) {
    return repository.signUp(params.email, params.password);
  }
}

class SignUpParams {
  final String email;
  final String password;
  SignUpParams({required this.email, required this.password});
}