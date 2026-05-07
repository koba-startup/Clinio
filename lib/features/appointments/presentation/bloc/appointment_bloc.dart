import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/entities/appointment_entity.dart';
import '../../domain/use_cases/add_appointment_usecase.dart';
import '../../domain/use_cases/delete_appointments_usecase.dart';
import '../../domain/use_cases/get_appointments_usecase.dart';
import '../../domain/use_cases/update_appointments_usecase.dart';

part 'appointment_event.dart';

part 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final GetAppointmentsUseCase getAppointmentsUseCase;
  final AddAppointmentUseCase addAppointmentUseCase;
  final UpdateAppointmentUseCase updateAppointmentUseCase;
  final DeleteAppointmentUseCase deleteAppointmentUseCase;

  StreamSubscription? _appointmentsSubscription;

  AppointmentBloc({
    required this.getAppointmentsUseCase,
    required this.addAppointmentUseCase,
    required this.updateAppointmentUseCase,
    required this.deleteAppointmentUseCase,
  }) : super(AppointmentInitial()) {
    // 1. Escuchar citas en tiempo real
    on<GetAppointmentsStarted>((event, emit) {
      emit(AppointmentLoading());
      _appointmentsSubscription?.cancel();
      _appointmentsSubscription = getAppointmentsUseCase(event.dentistId)
          .listen(
            (appointments) => add(AppointmentsUpdated(appointments)),
            onError: (error) => add(AppointmentsUpdated(const [])),
          );
    });

    on<AppointmentsUpdated>(
      (event, emit) => emit(AppointmentLoaded(event.appointments)),
    );

    // 2. Operaciones de escritura (CRUD)
    on<AddAppointmentRequested>((event, emit) async {
      // Validar colisión antes de guardar
      if (state is AppointmentLoaded) {
        final collision = _findCollision(
          event.appointment,
          (state as AppointmentLoaded).appointments,
        );
        if (collision != null) {
          emit(
            AppointmentError(
              'Horario ocupado: ya tienes una cita con ${collision.patientName} '
              'a las ${_formatTime(collision.dateTime)}',
            ),
          );
          return;
        }
      }

      final result = await addAppointmentUseCase(
        AddAppointmentParams(
          appointment: event.appointment,
          dentistId: event.dentistId,
        ),
      );
      result.fold(
        (failure) => emit(AppointmentError(failure.message)),
        (_) => emit(AppointmentOperationSuccess()),
      );
    });

    on<UpdateAppointmentRequested>((event, emit) async {
      if (state is AppointmentLoaded) {
        // Excluir la cita actual de la validación (no colisiona consigo misma)
        final otherAppointments = (state as AppointmentLoaded).appointments
            .where((a) => a.id != event.appointment.id)
            .toList();

        final collision = _findCollision(event.appointment, otherAppointments);
        if (collision != null) {
          emit(
            AppointmentError(
              'Horario ocupado: ya tienes una cita con ${collision.patientName} '
              'a las ${_formatTime(collision.dateTime)}',
            ),
          );
          return;
        }
      }

      final result = await updateAppointmentUseCase(
        UpdateAppointmentParams(
          appointment: event.appointment,
          dentistId: event.dentistId,
        ),
      );
      result.fold(
        (failure) => emit(AppointmentError(failure.message)),
        (_) => emit(AppointmentOperationSuccess()),
      );
    });

    on<DeleteAppointmentRequested>((event, emit) async {
      final result = await deleteAppointmentUseCase(
        DeleteAppointmentParams(
          appointmentId: event.appointmentId,
          dentistId: event.dentistId,
        ),
      );
      result.fold(
        (failure) => emit(AppointmentError(failure.message)),
        (_) => emit(AppointmentOperationSuccess()),
      );
    });
  }

  @override
  Future<void> close() {
    _appointmentsSubscription?.cancel();
    return super.close();
  }

  AppointmentEntity? _findCollision(
    AppointmentEntity newAppt,
    List<AppointmentEntity> existing,
  ) {
    final newStart = newAppt.dateTime;
    final newEnd = newAppt.dateTime.add(
      Duration(minutes: newAppt.durationMinutes),
    );

    for (final appt in existing) {
      // Las citas canceladas no bloquean el horario
      if (appt.status == AppointmentStatus.cancelled) continue;

      final existingStart = appt.dateTime;
      final existingEnd = appt.dateTime.add(
        Duration(minutes: appt.durationMinutes),
      );

      // Hay colisión si los rangos se solapan
      final overlaps =
          newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);
      if (overlaps) return appt;
    }
    return null;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
