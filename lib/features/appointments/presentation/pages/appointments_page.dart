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
                if (details.appointments != null && details.appointments!.isNotEmpty) {
                  final appo = details.appointments!.first as AppointmentEntity;
                  _showAppointmentDetail(context, appo, dentistId);
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

  void _showAppointmentDetail(
      BuildContext context,
      AppointmentEntity appo,
      String dentistId,
      ) {
    final appointmentBloc = context.read<AppointmentBloc>();

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appo.patientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(appo.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              appo.treatment,
              style: const TextStyle(fontSize: 15),
            ),
            Text(
              '${_formatTime(appo.dateTime)} · ${appo.durationMinutes} min',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (appo.notes != null && appo.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                appo.notes!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            const Divider(height: 28),

            // Acciones de estado
            const Text(
              'Cambiar estado',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (appo.status != AppointmentStatus.confirmed)
                  _statusButton(
                    label: 'Confirmar',
                    color: Colors.orange,
                    onTap: () {
                      _updateStatus(
                        appointmentBloc, appo, dentistId,
                        AppointmentStatus.confirmed,
                      );
                      Navigator.pop(context);
                    },
                  ),
                if (appo.status != AppointmentStatus.completed)
                  _statusButton(
                    label: 'Completada',
                    color: Colors.green,
                    onTap: () {
                      _updateStatus(
                        appointmentBloc, appo, dentistId,
                        AppointmentStatus.completed,
                      );
                      Navigator.pop(context);
                    },
                  ),
                if (appo.status != AppointmentStatus.cancelled)
                  _statusButton(
                    label: 'Cancelar',
                    color: Colors.red,
                    onTap: () {
                      _updateStatus(
                        appointmentBloc, appo, dentistId,
                        AppointmentStatus.cancelled,
                      );
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _updateStatus(
      AppointmentBloc bloc,
      AppointmentEntity appo,
      String dentistId,
      AppointmentStatus newStatus,
      ) {
    // Creamos una copia del entity con el nuevo estado
    final updated = AppointmentEntity(
      id: appo.id,
      patientId: appo.patientId,
      patientName: appo.patientName,
      dateTime: appo.dateTime,
      treatment: appo.treatment,
      durationMinutes: appo.durationMinutes,
      notes: appo.notes,
      status: newStatus,
    );
    bloc.add(UpdateAppointmentRequested(updated, dentistId));
  }

  Widget _statusButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      child: Text(label),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

}

class _StatusChip extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AppointmentStatus.pending   => ('Pendiente',  Colors.blueAccent),
      AppointmentStatus.confirmed => ('Confirmada', Colors.orange),
      AppointmentStatus.completed => ('Completada', Colors.green),
      AppointmentStatus.cancelled => ('Cancelada',  Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
