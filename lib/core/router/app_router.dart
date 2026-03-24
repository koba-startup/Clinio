import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/patients/presentation/pages/patients_page.dart';

class AppRouter {
  static const String login = '/login';
  static const String appointments = '/';
  static const String patients = '/patients';

  static final router = GoRouter(
    initialLocation: appointments,
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
