import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../../core/entities/appointment_entity.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../bloc/appointment_bloc.dart';
import '../widgets/add_appointment_modal.dart';
import '../widgets/appointment_data_source.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final CalendarController _calendarController = CalendarController();

  // Guardamos las citas localmente para evitar que desaparezcan durante estados de transición
  List<AppointmentEntity> _currentAppointments = [];

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final dentistId = authState
        .userId; // Verifica si es .user.id o .userId según tu AuthState

    return BlocProvider(
      create: (context) =>
          sl<AppointmentBloc>()..add(GetAppointmentsStarted(dentistId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agenda Clinio'),
          actions: [
            PopupMenuButton<CalendarView>(
              icon: const Icon(Icons.calendar_view_month),
              onSelected: (view) =>
                  setState(() => _calendarController.view = view),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: CalendarView.day,
                  child: Text('Día'),
                ),
                const PopupMenuItem(
                  value: CalendarView.week,
                  child: Text('Semana'),
                ),
                const PopupMenuItem(
                  value: CalendarView.month,
                  child: Text('Mes'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        // CAMBIO CLAVE: Usamos BlocConsumer
        body: BlocConsumer<AppointmentBloc, AppointmentState>(
          listener: (context, state) {
            if (state is AppointmentOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Cita guardada con éxito!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is AppointmentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            // Actualizamos nuestra lista local si el estado es Loaded
            if (state is AppointmentLoaded) {
              _currentAppointments = state.appointments;
            }

            if (state is AppointmentLoading && _currentAppointments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Siempre mostramos el calendario si tenemos datos,
            // incluso si el estado actual es "OperationSuccess"
            return SfCalendar(
              controller: _calendarController,
              view: CalendarView.day,
              dataSource: AppointmentDataSource(_currentAppointments),
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 7,
                endHour: 20,
              ),
              onTap: (details) {
                if (details.appointments != null &&
                    details.appointments!.isNotEmpty) {
                  final appo = details.appointments!.first as AppointmentEntity;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Paciente: ${appo.patientName}')),
                  );
                }
              },
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _showAddAppointment(context, dentistId),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Clinio Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Pacientes'),
            onTap: () {
              Navigator.pop(context);
              context.push('/patients');
            },
          ),
        ],
      ),
    );
  }

  void _showAddAppointment(BuildContext context, String dentistId) {
    final appointmentBloc = context.read<AppointmentBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: appointmentBloc),
          BlocProvider(
            create: (context) =>
                sl<PatientBloc>()..add(GetPatientsStarted(dentistId)),
          ),
        ],
        child: AddAppointmentModal(
          dentistId: dentistId,
          onSave: (newAppo) {
            appointmentBloc.add(AddAppointmentRequested(newAppo, dentistId));
          },
        ),
      ),
    );
  }
}
