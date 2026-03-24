import 'package:dartz/dartz.dart';

import '../../../../core/entities/patient_entity.dart';
import '../../../../core/error/failure.dart';

abstract class PatientRepository {
  // Obtener todos los pacientes del dentista actual
  Stream<List<PatientEntity>> getPatients(String dentistId);

  // CRUD básico
  Future<Either<Failure, void>> addPatient(
    PatientEntity patient,
    String dentistId,
  );

  Future<Either<Failure, void>> updatePatient(
    PatientEntity patient,
    String dentistId,
  );

  Future<Either<Failure, void>> deletePatient(
    String patientId,
    String dentistId,
  );
}
