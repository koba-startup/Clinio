import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/patients/presentation/pages/patients_page.dart';
import '../../injection_container.dart';

class AppRouter {
  static const String login = '/login';
  static const String appointments = '/';
  static const String patients = '/patients';

  static final router = GoRouter(
    initialLocation: login,
    refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
    redirect: (context, state) {

      final authState = context.read<AuthBloc>().state;
      final bool loggingIn = state.matchedLocation == login;

      if (authState is Unauthenticated && !loggingIn) {
        return login;
      }

      if (authState is Authenticated && loggingIn) {
        return appointments;
      }

      return null;
    },

    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginPage()),
      GoRoute(
        path: appointments,
        builder: (context, state) => const AppointmentsPage(),
      ),
      GoRoute(
        path: patients,
        builder: (context, state) => const PatientsPage(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
