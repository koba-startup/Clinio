import 'package:equatable/equatable.dart';

enum AppointmentStatus { pending, completed, cancelled }

class AppointmentEntity extends Equatable {
  final String id;
  final String patientId;
  final String patientName; // Denormalizamos el nombre para no hacer "joins" caros en Firestore
  final DateTime dateTime;
  final String description;
  final AppointmentStatus status;

  const AppointmentEntity({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    this.description = '',
    this.status = AppointmentStatus.pending,
  });

  @override
  List<Object?> get props => [id, patientId, patientName, dateTime, description, status];
}