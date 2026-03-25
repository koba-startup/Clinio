import '../../../../core/entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentsUseCase {
  final AppointmentRepository repository;

  GetAppointmentsUseCase(this.repository);

  Stream<List<AppointmentEntity>> call(String dentistId) {
    return repository.getAppointments(dentistId);
  }
}
