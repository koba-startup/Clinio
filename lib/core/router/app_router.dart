import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clinio/features/appointments/presentation/pages/appointments_page.dart';
import 'package:clinio/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clinio/features/auth/presentation/pages/login_page.dart';
import 'package:clinio/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:clinio/features/patients/presentation/pages/add_patients_page.dart';
import 'package:clinio/features/patients/presentation/pages/detail_patient_page.dart';
import 'package:clinio/features/patients/presentation/pages/patients_page.dart';
import 'package:clinio/injection_container.dart';
import 'package:clinio/core/entities/patient_entity.dart';
import 'package:clinio/features/patients/presentation/pages/edit_patients_page.dart';

class AppRouter {
  static const String login = '/login';
  static const String appointments = '/';
  static const String patients = '/patients';
  static const String patientDetail = '/patients/detail';
  static const String patientEdit = '/patients/edit';
  static const String addPatients = '/addPatients';

  static final router = GoRouter(
    initialLocation: login,
    refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
    redirect: (context, state) {

      final authState = context.read<AuthBloc>().state;
      final bool loggingIn = state.matchedLocation == login;

      if (authState is Unauthenticated && !loggingIn) return login;
      if (authState is Authenticated && loggingIn) return appointments;

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
      GoRoute(
        path: patientDetail,
        builder: (context, state) {
          // Recibimos el patient, el BLoC activo y el dentistId via extra
          // Así no hay nueva suscripción a Firestore ni petición extra
          final extra = state.extra as Map<String, dynamic>;
          return DetailPatientPage(
            patient: extra['patient'] as PatientEntity,
            patientBloc: extra['bloc'] as PatientBloc,
            dentistId: extra['dentistId'] as String,
          );
        },
      ),
      GoRoute(
        path: patientEdit,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return EditPatientPage(
            patient: extra['patient'] as PatientEntity,
            patientBloc: extra['bloc'] as PatientBloc,
            dentistId: extra['dentistId'] as String,
          );
        },
      ),
      GoRoute(path: addPatients, builder: (_, __) => const AddPatientsPage()),
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
