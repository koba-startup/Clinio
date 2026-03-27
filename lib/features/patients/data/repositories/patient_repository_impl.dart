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

  PatientRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  // Mapea el Stream de Models a Entities para respetar la Clean Architecture
  @override
  Stream<List<PatientEntity>> getPatients(String dentistId) {
    return remoteDataSource
        .getPatients(dentistId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Either<Failure, void>> addPatient(
    PatientEntity patient,
    String dentistId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(ServerFailure('Sin conexión a internet'));
    }
    try {
      await remoteDataSource.addPatient(
        PatientModel.fromEntity(patient),
        dentistId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePatient(
    PatientEntity patient,
    String dentistId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(ServerFailure('Sin conexión a internet'));
    }
    try {
      await remoteDataSource.updatePatient(
        PatientModel.fromEntity(patient),
        dentistId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePatient(
    String patientId,
    String dentistId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(ServerFailure('Sin conexión a internet'));
    }
    try {
      await remoteDataSource.deletePatient(patientId, dentistId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
