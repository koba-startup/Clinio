import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Fallo cuando no hay internet o el servidor falla
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error de conexión con el servidor']);
}

// Fallo específico para Firebase Auth (ej. contraseña incorrecta)
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

// Fallo cuando el usuario intenta hacer algo sin permisos
class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'No tienes permisos para realizar esta acción',
  ]);
}
