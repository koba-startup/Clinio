import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../../core/entities/appointment_entity.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/appointment_bloc.dart';
import '../widgets/appointment_data_source.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final CalendarController _calendarController = CalendarController();

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Validación segura del estado de autenticación (como hicimos en Patients)
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final dentistId = authState.userId;

    return BlocProvider(
      create: (context) =>
          sl<AppointmentBloc>()..add(GetAppointmentsStarted(dentistId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agenda Clinio'),
          actions: [
            // Selector de Vista (Día, Semana, Mes)
            PopupMenuButton<CalendarView>(
              icon: const Icon(Icons.calendar_view_month),
              tooltip: 'Cambiar vista',
              onSelected: (CalendarView view) {
                setState(() {
                  _calendarController.view = view;
                });
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<CalendarView>>[
                    const PopupMenuItem<CalendarView>(
                      value: CalendarView.day,
                      child: Text('Día (Hoy)'),
                    ),
                    const PopupMenuItem<CalendarView>(
                      value: CalendarView.week,
                      child: Text('Semana'),
                    ),
                    const PopupMenuItem<CalendarView>(
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
        drawer: Drawer(
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
        ),
        body: BlocBuilder<AppointmentBloc, AppointmentState>(
          builder: (context, state) {
            if (state is AppointmentLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AppointmentLoaded) {
              return SfCalendar(
                controller: _calendarController,
                view: CalendarView.day,
                // Vista por default: Día
                dataSource: AppointmentDataSource(state.appointments),
                // Configuramos el horario laboral del dentista
                timeSlotViewSettings: const TimeSlotViewSettings(
                  startHour: 7, // Empieza a las 7 AM
                  endHour: 20, // Termina a las 8 PM
                ),
                onTap: (CalendarTapDetails details) {
                  // Si toca una cita existente, podríamos abrir sus detalles
                  if (details.appointments != null &&
                      details.appointments!.isNotEmpty) {
                    final AppointmentEntity appo = details.appointments!.first;
                    // TODO: Mostrar diálogo de detalles/edición
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cita seleccionada: ${appo.patientName}'),
                      ),
                    );
                  }
                },
              );
            } else if (state is AppointmentError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () {
              // TODO: Abrir el formulario para agregar cita
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
