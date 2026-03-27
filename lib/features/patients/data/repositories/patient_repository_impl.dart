import 'package:dartz/dartz.dart';

import '../../../../core/entities/patient_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasource/patient_remote_data_source.dart';
import '../models/patient_model.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PatientRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Stream<List<PatientEntity>> getPatients(String dentistId) {
    return remoteDataSource.getPatients(dentistId);
  }

  @override
  Future<Either<Failure, void>> addPatient(PatientEntity patient, String dentistId) async {
    if (await networkInfo.isConnected) {
      try {
        // Mapeamos la entidad a modelo para poder enviarla a Firestore
        final model = PatientModel(
          id: patient.id,
          name: patient.name,
          phone: patient.phone,
          email: patient.email,
          createdAt: patient.createdAt,
        );
        await remoteDataSource.addPatient(model, dentistId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePatient(dynamic patient, String dentistId) async { /* ... */ return const Right(null); }
  @override
  Future<Either<Failure, void>> deletePatient(String patientId, String dentistId) async { /* ... */ return const Right(null); }
}