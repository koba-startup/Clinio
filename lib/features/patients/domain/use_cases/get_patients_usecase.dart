import '../../../../core/entities/patient_entity.dart';
import '../repositories/patient_repository.dart';

class GetPatientsUseCase {
  final PatientRepository repository;
  GetPatientsUseCase(this.repository);

  Stream<List<PatientEntity>> call(String dentistId) {
    return repository.getPatients(dentistId);
  }
}