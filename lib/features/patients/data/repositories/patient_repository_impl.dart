import 'dart:io';
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
      // 1. Generar el ID de Firestore ANTES de subir la foto
      //    Así Storage y Firestore siempre usan la misma ruta
      final patientId = remoteDataSource.generatePatientId(dentistId);

      String? finalPhotoUrl;
      if (patient.photoUrl != null && patient.photoUrl!.startsWith('/')) {
        // 2. Subir foto con el ID ya conocido
        finalPhotoUrl = await remoteDataSource.uploadPatientPhoto(
          File(patient.photoUrl!),
          dentistId,
          patientId, // ID real, no timestamp temporal
        );
      }

      // 3. Guardar documento con ese mismo ID
      final model = PatientModel.fromEntity(
        PatientEntity(
          id: patientId,
          // ID pre-generado
          name: patient.name,
          phone: patient.phone,
          email: patient.email,
          observations: patient.observations,
          photoUrl: finalPhotoUrl,
          createdAt: patient.createdAt,
        ),
      );

      await remoteDataSource.addPatient(model, dentistId);
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
      String? finalPhotoUrl = patient.photoUrl;

      // Path local = foto nueva → subir y sobrescribir la anterior
      if (patient.photoUrl != null && patient.photoUrl!.startsWith('/')) {
        finalPhotoUrl = await remoteDataSource.uploadPatientPhoto(
          File(patient.photoUrl!),
          dentistId,
          patient.id, // ID real del paciente
        );
      }

      // null explícito = usuario quitó la foto → eliminar de Storage
      if (patient.photoUrl == null) {
        await remoteDataSource.deletePatientPhoto(dentistId, patient.id);
      }

      final model = PatientModel.fromEntity(
        PatientEntity(
          id: patient.id,
          name: patient.name,
          phone: patient.phone,
          email: patient.email,
          observations: patient.observations,
          photoUrl: finalPhotoUrl,
          createdAt: patient.createdAt,
        ),
      );

      await remoteDataSource.updatePatient(model, dentistId);
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
      // deletePatient en datasource elimina foto + documento
      await remoteDataSource.deletePatient(patientId, dentistId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
