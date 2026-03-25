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
}
