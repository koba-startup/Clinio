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

enum _AgendaView { day, week, month }

class _AppointmentsPageState extends State<AppointmentsPage> {
  final CalendarController _calendarController = CalendarController();
  List<AppointmentEntity> _currentAppointments = [];
  _AgendaView _currentView = _AgendaView.day;

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
          title: Text(switch (_currentView) {
            _AgendaView.day => 'Mi día',
            _AgendaView.week => 'Mi semana',
            _AgendaView.month => 'Mi mes',
          }),
          actions: [
            // Toggle entre vista diaria y calendario
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SegmentedButton<_AgendaView>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                segments: const [
                  ButtonSegment(
                    value: _AgendaView.day,
                    icon: Icon(Icons.view_day, size: 18),
                    tooltip: 'Hoy',
                  ),
                  ButtonSegment(
                    value: _AgendaView.week,
                    icon: Icon(Icons.view_week, size: 18),
                    tooltip: 'Semana',
                  ),
                  ButtonSegment(
                    value: _AgendaView.month,
                    icon: Icon(Icons.calendar_month, size: 18),
                    tooltip: 'Mes',
                  ),
                ],
                selected: {_currentView},
                onSelectionChanged: (selection) =>
                    setState(() => _currentView = selection.first),
              ),
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

            return switch (_currentView) {
              _AgendaView.day => _buildDayView(context, dentistId),
              _AgendaView.week => _buildWeekView(context, dentistId),
              _AgendaView.month => _buildCalendar(context, dentistId),
            };
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

  Widget _buildWeekView(BuildContext context, String dentistId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    const dayNames = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const startHour = 8;
    const endHour = 20;
    const hourHeight = 64.0;
    const timeColWidth = 44.0;

    return Column(
      children: [
        // ── Header días ────────────────────────────────────────────────
        Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              SizedBox(width: timeColWidth), // espacio para columna de horas
              ...List.generate(7, (i) {
                final day = startOfWeek.add(Duration(days: i));
                final isToday =
                    day.day == now.day &&
                    day.month == now.month &&
                    day.year == now.year;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: isToday
                        ? BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          )
                        : null,
                    child: Column(
                      children: [
                        Text(
                          dayNames[day.weekday],
                          style: TextStyle(
                            fontSize: 11,
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Grilla scrolleable ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: (endHour - startHour) * hourHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna de horas
                  SizedBox(
                    width: timeColWidth,
                    child: Column(
                      children: List.generate(endHour - startHour, (i) {
                        return SizedBox(
                          height: hourHeight,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${(startHour + i).toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Columnas de cada día
                  ...List.generate(7, (dayIndex) {
                    final day = startOfWeek.add(Duration(days: dayIndex));
                    final isToday =
                        day.day == now.day &&
                        day.month == now.month &&
                        day.year == now.year;

                    // Citas del día sin canceladas
                    final dayAppts = _currentAppointments
                        .where(
                          (a) =>
                              a.status != AppointmentStatus.cancelled &&
                              a.dateTime.year == day.year &&
                              a.dateTime.month == day.month &&
                              a.dateTime.day == day.day,
                        )
                        .toList();

                    return Expanded(
                      child: Stack(
                        children: [
                          // Fondo con líneas por hora y color de hoy
                          Column(
                            children: List.generate(endHour - startHour, (i) {
                              return Container(
                                height: hourHeight,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.15)
                                      : Colors.transparent,
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.withOpacity(0.15),
                                    ),
                                    left: BorderSide(
                                      color: Colors.grey.withOpacity(0.15),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          // Bloques de citas posicionados
                          ...dayAppts.map((appt) {
                            final startMinutes =
                                (appt.dateTime.hour - startHour) * 60 +
                                appt.dateTime.minute;
                            final topOffset = startMinutes * hourHeight / 60;
                            final blockHeight =
                                appt.durationMinutes * hourHeight / 60;

                            // No renderizar si está fuera del rango visible
                            if (startMinutes < 0 ||
                                appt.dateTime.hour >= endHour) {
                              return const SizedBox.shrink();
                            }

                            return Positioned(
                              top: topOffset,
                              left: 1,
                              right: 1,
                              height: blockHeight.clamp(20.0, double.infinity),
                              child: GestureDetector(
                                onTap: () => _showAppointmentDetail(
                                  context,
                                  appt,
                                  dentistId,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      appt.status,
                                    ).withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appt.patientName.split(' ').first,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (blockHeight > 32)
                                        Text(
                                          appt.treatment,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.white70,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Línea de hora actual — solo en el día de hoy
                          if (isToday &&
                              now.hour >= startHour &&
                              now.hour < endHour)
                            Positioned(
                              top:
                                  ((now.hour - startHour) * 60 + now.minute) *
                                  hourHeight /
                                  60,
                              left: 0,
                              right: 0,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1.5,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper de color — agregar junto a _formatTime y _formatDate
  Color _statusColor(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.pending => Colors.blueAccent,
      AppointmentStatus.confirmed => Colors.orange,
      AppointmentStatus.completed => Colors.green,
      AppointmentStatus.cancelled => Colors.red,
    };
  }

  // ─── VISTA DIARIA ────────────────────────────────────────────────────────

  Widget _buildDayView(BuildContext context, String dentistId) {
    final now = DateTime.now();
    const startHour = 8;
    const endHour = 20;

    final dayStart = DateTime(now.year, now.month, now.day, startHour);
    final dayEnd = DateTime(now.year, now.month, now.day, endHour);

    // Citas del día ordenadas, sin canceladas
    final todayAppts =
        _currentAppointments
            .where(
              (a) =>
                  a.status != AppointmentStatus.cancelled &&
                  a.dateTime.year == now.year &&
                  a.dateTime.month == now.month &&
                  a.dateTime.day == now.day,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Construir lista de bloques: ocupados y libres intercalados
    final List<_DayBlock> blocks = [];
    DateTime cursor = dayStart;

    for (final appt in todayAppts) {
      final apptStart = appt.dateTime;
      final apptEnd = appt.dateTime.add(
        Duration(minutes: appt.durationMinutes),
      );

      // Ignorar citas fuera del rango visible
      if (apptEnd.isBefore(dayStart) || apptStart.isAfter(dayEnd)) continue;

      // Bloque libre antes de esta cita
      if (apptStart.isAfter(cursor)) {
        final freeMinutes = apptStart.difference(cursor).inMinutes;
        blocks.add(_DayBlock.free(start: cursor, minutes: freeMinutes));
      }

      // Bloque de cita
      blocks.add(_DayBlock.appointment(appt));
      cursor = apptEnd.isAfter(dayEnd) ? dayEnd : apptEnd;
    }

    // Bloque libre al final del día
    if (cursor.isBefore(dayEnd)) {
      final freeMinutes = dayEnd.difference(cursor).inMinutes;
      blocks.add(_DayBlock.free(start: cursor, minutes: freeMinutes));
    }

    return Column(
      children: [
        // Encabezado
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

        // Lista de bloques
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              final block = blocks[index];
              return block.isAppointment
                  ? _AppointmentBlock(
                      appointment: block.appointment!,
                      onTap: () => _showAppointmentDetail(
                        context,
                        block.appointment!,
                        dentistId,
                      ),
                    )
                  : _FreeBlock(start: block.start!, minutes: block.minutes!);
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

// ─── Modelo de bloque de tiempo ──────────────────────────────────────────────

class _DayBlock {
  final bool isAppointment;
  final AppointmentEntity? appointment;
  final DateTime? start;
  final int? minutes;

  const _DayBlock._({
    required this.isAppointment,
    this.appointment,
    this.start,
    this.minutes,
  });

  factory _DayBlock.appointment(AppointmentEntity appt) =>
      _DayBlock._(isAppointment: true, appointment: appt);

  factory _DayBlock.free({required DateTime start, required int minutes}) =>
      _DayBlock._(isAppointment: false, start: start, minutes: minutes);
}

// ─── Bloque de cita ───────────────────────────────────────────────────────────

class _AppointmentBlock extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback onTap;

  const _AppointmentBlock({required this.appointment, required this.onTap});

  Color _statusColor(AppointmentStatus status) => switch (status) {
    AppointmentStatus.pending => Colors.blueAccent,
    AppointmentStatus.confirmed => Colors.orange,
    AppointmentStatus.completed => Colors.green,
    AppointmentStatus.cancelled => Colors.red,
  };

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes} min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(appointment.status);
    final endTime = appointment.dateTime.add(
      Duration(minutes: appointment.durationMinutes),
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
          // Barra de color izquierda
        ),
        child: Row(
          children: [
            // Barra de color
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Info de la cita
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment.treatment,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Hora y duración
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatTime(appointment.dateTime)} – ${_formatTime(endTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(appointment.durationMinutes),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bloque libre ─────────────────────────────────────────────────────────────

class _FreeBlock extends StatelessWidget {
  final DateTime start;
  final int minutes;

  const _FreeBlock({required this.start, required this.minutes});

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes} min libres';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h libres' : '${h}h ${m}min libres';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatTime(start),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatDuration(minutes),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
