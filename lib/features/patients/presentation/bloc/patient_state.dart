part of 'patient_bloc.dart';

sealed class PatientState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {}

class PatientLoading extends PatientState {}

class PatientLoaded extends PatientState {
  final List<PatientEntity> patients;

  PatientLoaded(this.patients);

  @override
  List<Object?> get props => [patients];
}

class PatientError extends PatientState {
  final String message;

  PatientError(this.message);

  @override
  List<Object?> get props => [message];
}

class PatientOperationSuccess extends PatientState {}
