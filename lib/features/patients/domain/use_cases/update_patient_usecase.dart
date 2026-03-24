import 'package:dartz/dartz.dart';

import '../../../../core/entities/patient_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/use_cases/use_case.dart';
import '../repositories/patient_repository.dart';

class UpdatePatientUseCase implements UseCase<void, UpdatePatientParams> {
  final PatientRepository repository;

  UpdatePatientUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePatientParams params) {
    return repository.updatePatient(params.patient, params.dentistId);
  }
}

class UpdatePatientParams {
  final PatientEntity patient;
  final String dentistId;

  UpdatePatientParams({required this.patient, required this.dentistId});
}
