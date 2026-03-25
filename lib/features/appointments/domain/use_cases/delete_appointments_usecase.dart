import 'package:clinio/core/use_cases/use_case.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/appointment_repository.dart';

class DeleteAppointmentUseCase
    implements UseCase<void, DeleteAppointmentParams> {
  final AppointmentRepository repository;

  DeleteAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAppointmentParams params) {
    return repository.deleteAppointment(params.appointmentId, params.dentistId);
  }
}

class DeleteAppointmentParams {
  final String appointmentId;
  final String dentistId;

  DeleteAppointmentParams({
    required this.appointmentId,
    required this.dentistId,
  });
}
