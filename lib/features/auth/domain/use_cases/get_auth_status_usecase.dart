import '../repositories/auth_repository.dart';

class GetAuthStatusUseCase {
  final AuthRepository repository;

  GetAuthStatusUseCase(this.repository);

  Stream<String?> call() {
    return repository.onAuthStateChanged;
  }
}