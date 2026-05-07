import 'package:equatable/equatable.dart';

enum AppointmentStatus { pending, confirmed, completed, cancelled }

class AppointmentEntity extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final int durationMinutes; // ← nuevo: para calcular espacios libres
  final String treatment;    // ← nuevo: "Limpieza", "Extracción", etc.
  final String? notes;       // ← description renombrado, ahora opcional
  final AppointmentStatus status;

  const AppointmentEntity({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.treatment,
    this.durationMinutes = 60, // 1 hora por default
    this.notes,
    this.status = AppointmentStatus.pending,
  });

  @override
  List<Object?> get props => [
    id, patientId, patientName, dateTime,
    durationMinutes, treatment, notes, status,
  ];
}