part of 'appointment_bloc.dart';

sealed class AppointmentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetAppointmentsStarted extends AppointmentEvent {
  final String dentistId;

  GetAppointmentsStarted(this.dentistId);
}

class AppointmentsUpdated extends AppointmentEvent {
  final List<AppointmentEntity> appointments;

  AppointmentsUpdated(this.appointments);
}

class AddAppointmentRequested extends AppointmentEvent {
  final AppointmentEntity appointment;
  final String dentistId;

  AddAppointmentRequested(this.appointment, this.dentistId);
}

class UpdateAppointmentRequested extends AppointmentEvent {
  final AppointmentEntity appointment;
  final String dentistId;

  UpdateAppointmentRequested(this.appointment, this.dentistId);
}

class DeleteAppointmentRequested extends AppointmentEvent {
  final String appointmentId;
  final String dentistId;

  DeleteAppointmentRequested(this.appointmentId, this.dentistId);
}
