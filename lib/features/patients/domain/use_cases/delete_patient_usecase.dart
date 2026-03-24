import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/use_cases/use_case.dart';
import '../repositories/patient_repository.dart';

class DeletePatientUseCase implements UseCase<void, DeletePatientParams> {
  final PatientRepository repository;

  DeletePatientUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePatientParams params) {
    return repository.deletePatient(params.patientId, params.dentistId);
  }
}

class DeletePatientParams {
  final String patientId;
  final String dentistId;

  DeletePatientParams({required this.patientId, required this.dentistId});
}
