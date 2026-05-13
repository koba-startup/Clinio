import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/entities/appointment_entity.dart';
import '../../../../core/entities/patient_entity.dart';
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
  List<AppointmentEntity> _currentAppointments = [];
  bool _showCalendar = false; // ← vista diaria es la default

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
    final dentistId = authState.userId;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<AppointmentBloc>()..add(GetAppointmentsStarted(dentistId)),
        ),
        BlocProvider(
          create: (context) =>
              sl<PatientBloc>()..add(GetPatientsStarted(dentistId)),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_showCalendar ? 'Calendario' : 'Mi día'),
          actions: [
            // Toggle entre vista diaria y calendario
            IconButton(
              icon: Icon(
                _showCalendar ? Icons.view_list : Icons.calendar_month,
              ),
              tooltip: _showCalendar ? 'Ver lista del día' : 'Ver calendario',
              onPressed: () => setState(() => _showCalendar = !_showCalendar),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
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
            if (state is AppointmentLoaded) {
              _currentAppointments = state.appointments;
            }

            if (state is AppointmentLoading && _currentAppointments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return _showCalendar
                ? _buildCalendar(context, dentistId)
                : _buildDayView(context, dentistId);
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

  // ─── VISTA DIARIA ────────────────────────────────────────────────────────

  Widget _buildDayView(BuildContext context, String dentistId) {
    final now = DateTime.now();
    final todayAppts =
        _currentAppointments
            .where(
              (a) =>
                  a.dateTime.year == now.year &&
                  a.dateTime.month == now.month &&
                  a.dateTime.day == now.day &&
                  a.status != AppointmentStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Horario del consultorio: 8am a 8pm en slots de 1 hora
    final slots = List.generate(12, (i) => TimeOfDay(hour: 8 + i, minute: 0));

    return Column(
      children: [
        // Encabezado de fecha
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(now),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                todayAppts.isEmpty
                    ? 'Sin citas hoy'
                    : '${todayAppts.length} cita${todayAppts.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        // Lista de slots del día
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final slotStart = DateTime(
                now.year,
                now.month,
                now.day,
                slot.hour,
                slot.minute,
              );
              final slotEnd = slotStart.add(const Duration(hours: 1));

              // Buscar cita que ocupe este slot
              final appt = todayAppts.where((a) {
                final end = a.dateTime.add(
                  Duration(minutes: a.durationMinutes),
                );
                return a.dateTime.isBefore(slotEnd) && end.isAfter(slotStart);
              }).firstOrNull;

              return _SlotTile(
                slotTime: slot,
                appointment: appt,
                onTap: appt != null
                    ? () => _showAppointmentDetail(context, appt, dentistId)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── VISTA CALENDARIO ────────────────────────────────────────────────────

  Widget _buildCalendar(BuildContext context, String dentistId) {
    return SfCalendar(
      controller: _calendarController,
      view: CalendarView.month,
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
  }

  // ─── DETAIL / ACCIONES ───────────────────────────────────────────────────

  void _updateStatus(
    AppointmentBloc bloc,
    AppointmentEntity appo,
    String dentistId,
    AppointmentStatus newStatus,
  ) {
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

  // ─── DRAWER ──────────────────────────────────────────────────────────────

  void _showAddAppointment(BuildContext context, String dentistId) {
    final appointmentBloc = context.read<AppointmentBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: appointmentBloc),
          BlocProvider(
            create: (_) =>
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Clinio',
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

  // ─── ADD APPOINTMENT ─────────────────────────────────────────────────────

  void _showAppointmentDetail(
    BuildContext context,
    AppointmentEntity appo,
    String dentistId,
  ) {
    final appointmentBloc = context.read<AppointmentBloc>();

    // Buscar el paciente en memoria por patientId
    final patientState = context.read<PatientBloc>().state;
    PatientEntity? patient;
    if (patientState is PatientLoaded) {
      patient = patientState.patients
          .where((p) => p.id == appo.patientId)
          .firstOrNull;
    }

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
            Text(appo.treatment, style: const TextStyle(fontSize: 15)),
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

            // Botón WhatsApp — solo si encontramos el paciente y tiene teléfono
            if (patient != null && patient.phone.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Enviar recordatorio por WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    // verde WhatsApp
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _sendWhatsAppReminder(appo, patient!),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
                        appointmentBloc,
                        appo,
                        dentistId,
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
                        appointmentBloc,
                        appo,
                        dentistId,
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
                        appointmentBloc,
                        appo,
                        dentistId,
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

  Future<void> _sendWhatsAppReminder(
    AppointmentEntity appo,
    PatientEntity patient,
  ) async {
    // Limpiar el teléfono — quitar espacios, guiones, paréntesis
    // y asegurarse que tenga código de país
    String phone = patient.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!phone.startsWith('+')) {
      phone = '+52$phone'; // Agregar código de México si no tiene prefijo
    }
    // Quitar el + para el formato de wa.me
    phone = phone.replaceAll('+', '');

    final fecha =
        '${appo.dateTime.day}/${appo.dateTime.month}/${appo.dateTime.year}';
    final hora = _formatTime(appo.dateTime);

    final mensaje =
        'Hola ${appo.patientName} 👋, te recordamos que tienes una cita '
        'el *$fecha* a las *$hora* para *${appo.treatment}*. '
        '¿Confirmas tu asistencia? 😊';

    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(mensaje)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const days = [
      '',
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return '${days[dt.weekday]}, ${dt.day} de ${months[dt.month]}';
  }
}

// ─── WIDGETS AUXILIARES ──────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  final TimeOfDay slotTime;
  final AppointmentEntity? appointment;
  final VoidCallback? onTap;

  const _SlotTile({required this.slotTime, this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeLabel = '${slotTime.hour.toString().padLeft(2, '0')}:00';
    final isEmpty = appointment == null;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isEmpty
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
              : _statusColor(appointment!.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEmpty
                ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                : _statusColor(appointment!.status).withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            // Hora
            SizedBox(
              width: 48,
              child: Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isEmpty ? Colors.grey[500] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contenido del slot
            Expanded(
              child: isEmpty
                  ? Text(
                      'Disponible',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment!.patientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          appointment!.treatment,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
            ),

            // Indicador de estado
            if (!isEmpty) _StatusChip(appointment!.status),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.pending => Colors.blueAccent,
      AppointmentStatus.confirmed => Colors.orange,
      AppointmentStatus.completed => Colors.green,
      AppointmentStatus.cancelled => Colors.red,
    };
  }
}

class _StatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AppointmentStatus.pending => ('Pendiente', Colors.blueAccent),
      AppointmentStatus.confirmed => ('Confirmada', Colors.orange),
      AppointmentStatus.completed => ('Completada', Colors.green),
      AppointmentStatus.cancelled => ('Cancelada', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
