import 'package:dartz/dartz.dart';

import '../../../../core/entities/appointment_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/use_cases/use_case.dart';
import '../repositories/appointment_repository.dart';

class UpdateAppointmentUseCase
    implements UseCase<void, UpdateAppointmentParams> {
  final AppointmentRepository repository;

  UpdateAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateAppointmentParams params) {
    return repository.updateAppointment(params.appointment, params.dentistId);
  }
}

class UpdateAppointmentParams {
  final AppointmentEntity appointment;
  final String dentistId;

  UpdateAppointmentParams({required this.appointment, required this.dentistId});
}
