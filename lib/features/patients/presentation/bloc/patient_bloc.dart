import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/entities/patient_entity.dart';
import '../../domain/use_cases/add_patient_usecase.dart';
import '../../domain/use_cases/delete_patient_usecase.dart';
import '../../domain/use_cases/get_patients_usecase.dart';
import '../../domain/use_cases/update_patient_usecase.dart';

part 'patient_event.dart';

part 'patient_state.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final GetPatientsUseCase getPatientsUseCase;
  final AddPatientUseCase addPatientUseCase;
  final UpdatePatientUseCase updatePatientUseCase;
  final DeletePatientUseCase deletePatientUseCase;

  StreamSubscription? _patientsSubscription;

  PatientBloc({
    required this.getPatientsUseCase,
    required this.addPatientUseCase,
    required this.updatePatientUseCase,
    required this.deletePatientUseCase,
  }) : super(PatientInitial()) {
    on<GetPatientsStarted>((event, emit) {
      emit(PatientLoading());
      _patientsSubscription?.cancel();
      _patientsSubscription = getPatientsUseCase(event.dentistId).listen(
        (patients) => add(PatientsUpdated(patients)),
        onError: (error) => add(PatientsUpdated(const [])),
      );
    });

    on<PatientsUpdated>((event, emit) => emit(PatientLoaded(event.patients)));

    on<AddPatientRequested>((event, emit) async {
      final result = await addPatientUseCase(
        AddPatientParams(patient: event.patient, dentistId: event.dentistId),
      );
      result.fold(
        (failure) => emit(PatientError(failure.message)),
        (_) => emit(PatientOperationSuccess()),
      );
    });

    on<UpdatePatientRequested>((event, emit) async {
      final result = await updatePatientUseCase(
        UpdatePatientParams(patient: event.patient, dentistId: event.dentistId),
      );
      result.fold(
        (failure) => emit(PatientError(failure.message)),
        (_) => emit(PatientOperationSuccess()),
      );
    });

    on<DeletePatientRequested>((event, emit) async {
      final result = await deletePatientUseCase(
        DeletePatientParams(
          patientId: event.patientId,
          dentistId: event.dentistId,
        ),
      );
      result.fold(
        (failure) => emit(PatientError(failure.message)),
        (_) => emit(PatientOperationSuccess()),
      );
    });
  }

  @override
  Future<void> close() {
    _patientsSubscription?.cancel();
    return super.close();
  }
}
