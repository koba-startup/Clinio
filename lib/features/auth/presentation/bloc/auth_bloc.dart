import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/use_cases/use_case.dart';
import '../../domain/use_cases/get_auth_status_usecase.dart';
import '../../domain/use_cases/login_usecase.dart';
import '../../domain/use_cases/logout_usecase.dart';
import '../../domain/use_cases/signup_usecase.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetAuthStatusUseCase getAuthStatusUseCase;
  final SignUpUseCase signUpUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getAuthStatusUseCase,
    required this.signUpUseCase,
  }) : super(AuthInitial()) {
    // Escuchar cambios de autenticación en tiempo real

    on<AuthCheckRequested>((event, emit) async {
      await emit.forEach<String?>(
        getAuthStatusUseCase(),
        onData: (userId) =>
            userId != null ? Authenticated(userId) : Unauthenticated(),
      );
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await loginUseCase(
        LoginParams(email: event.email, password: event.password),
      );
      result.fold((failure) => emit(AuthError(failure.message)), (_) => null);
    });

    on<AuthLogoutRequested>((event, emit) async {
      await logoutUseCase(NoParams());
    });

    on<AuthSignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signUpUseCase(
        SignUpParams(email: event.email, password: event.password),
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) =>
            null, // El stream de Firebase detectará al nuevo usuario y emitirá Authenticated
      );
    });
  }
}
