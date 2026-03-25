import 'package:dartz/dartz.dart';
import '../../../../core/entities/appointment_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/use_cases/use_case.dart';
import '../repositories/appointment_repository.dart';

class AddAppointmentUseCase implements UseCase<void, AddAppointmentParams> {
  final AppointmentRepository repository;

  AddAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddAppointmentParams params) {
    return repository.addAppointment(params.appointment, params.dentistId);
  }
}

class AddAppointmentParams {
  final AppointmentEntity appointment;
  final String dentistId;

  AddAppointmentParams({required this.appointment, required this.dentistId});
}
