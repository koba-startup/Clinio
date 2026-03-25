import 'package:dartz/dartz.dart';
import '../../../../core/entities/appointment_entity.dart';
import '../../../../core/error/failure.dart';

abstract class AppointmentRepository {

  Stream<List<AppointmentEntity>> getAppointments(String dentistId);

  // CRUD
  Future<Either<Failure, void>> addAppointment(AppointmentEntity appointment, String dentistId);
  Future<Either<Failure, void>> updateAppointment(AppointmentEntity appointment, String dentistId);
  Future<Either<Failure, void>> deleteAppointment(String appointmentId, String dentistId);
}