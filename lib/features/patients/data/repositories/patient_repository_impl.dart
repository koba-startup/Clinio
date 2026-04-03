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
      String? finalPhotoUrl;

      // 1. Si hay una foto local (path), la procesamos y subimos primero
      if (patient.photoUrl != null && patient.photoUrl!.isNotEmpty) {
        final file = File(patient.photoUrl!);
        if (await file.exists()) {
          // El DataSource se encarga de la compresión WebP y redimensión
          finalPhotoUrl = await remoteDataSource.uploadPatientPhoto(
            file,
            dentistId,
            // Generamos un ID temporal o dejamos que Firestore lo maneje más adelante
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
        }
      }

      // 2. Creamos el modelo con la URL final (de internet) en lugar del path local
      final model = PatientModel(
        id: patient.id,
        name: patient.name,
        phone: patient.phone,
        email: patient.email,
        observations: patient.observations,
        photoUrl: finalPhotoUrl,
        // Aquí ya va la URL de Firebase Storage
        createdAt: patient.createdAt,
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
      String? updatedPhotoUrl = patient.photoUrl;

      // Si el photoUrl es un path local (comienza con /data o /Users), significa que es nueva
      if (patient.photoUrl != null && patient.photoUrl!.startsWith('/')) {
        updatedPhotoUrl = await remoteDataSource.uploadPatientPhoto(
          File(patient.photoUrl!),
          dentistId,
          patient.id,
        );
      }

      final model = PatientModel(
        id: patient.id,
        name: patient.name,
        phone: patient.phone,
        email: patient.email,
        observations: patient.observations,
        photoUrl: updatedPhotoUrl,
        createdAt: patient.createdAt,
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
      await remoteDataSource.deletePatient(patientId, dentistId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
