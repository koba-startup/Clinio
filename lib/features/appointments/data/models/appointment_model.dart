import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.patientId,
    required super.patientName,
    required super.dateTime,
    super.durationMinutes = 60,
    super.notes,
    super.status,
    required super.treatment,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      treatment: data['treatment'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 60,
      notes: data['notes'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'dateTime': Timestamp.fromDate(dateTime),
      'treatment': treatment,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'status': status.toString(),
    };
  }
}
