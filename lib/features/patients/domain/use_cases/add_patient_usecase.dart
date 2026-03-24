import 'package:dartz/dartz.dart';

import '../../../../core/entities/patient_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/use_cases/use_case.dart';
import '../repositories/patient_repository.dart';

class AddPatientUseCase implements UseCase<void, AddPatientParams> {
  final PatientRepository repository;

  AddPatientUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddPatientParams params) {
    return repository.addPatient(params.patient, params.dentistId);
  }
}

class AddPatientParams {
  final PatientEntity patient;
  final String dentistId;

  AddPatientParams({required this.patient, required this.dentistId});
}
