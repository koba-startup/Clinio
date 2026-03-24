part of 'patient_bloc.dart';

sealed class PatientEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetPatientsStarted extends PatientEvent {
  final String dentistId;

  GetPatientsStarted(this.dentistId);
}

class PatientsUpdated extends PatientEvent {
  final List<PatientEntity> patients;

  PatientsUpdated(this.patients);
}

class AddPatientRequested extends PatientEvent {
  final PatientEntity patient;
  final String dentistId;

  AddPatientRequested(this.patient, this.dentistId);
}

class UpdatePatientRequested extends PatientEvent {
  final PatientEntity patient;
  final String dentistId;

  UpdatePatientRequested(this.patient, this.dentistId);
}

class DeletePatientRequested extends PatientEvent {
  final String patientId;
  final String dentistId;

  DeletePatientRequested(this.patientId, this.dentistId);
}
