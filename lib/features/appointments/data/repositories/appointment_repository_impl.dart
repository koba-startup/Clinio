import 'package:dartz/dartz.dart';
import '../../../../core/entities/appointment_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasource/appointment_remote_data_source.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AppointmentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<List<AppointmentEntity>> getAppointments(String dentistId) {
    return remoteDataSource.getAppointments(dentistId);
  }

  @override
  Future<Either<Failure, void>> addAppointment(
    AppointmentEntity appointment,
    String dentistId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final model = AppointmentModel(
          id: appointment.id,
          patientId: appointment.patientId,
          patientName: appointment.patientName,
          dateTime: appointment.dateTime,
          description: appointment.description,
          status: appointment.status,
        );
        await remoteDataSource.addAppointment(model, dentistId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('Sin conexión'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAppointment(
    AppointmentEntity appointment,
    String dentistId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final model = AppointmentModel(
          id: appointment.id,
          patientId: appointment.patientId,
          patientName: appointment.patientName,
          dateTime: appointment.dateTime,
          description: appointment.description,
          status: appointment.status,
        );
        await remoteDataSource.updateAppointment(model, dentistId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAppointment(
    String appointmentId,
    String dentistId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteAppointment(appointmentId, dentistId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('Sin conexión a internet'));
    }
  }
}
