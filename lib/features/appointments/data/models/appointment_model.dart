import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.patientId,
    required super.patientName,
    required super.dateTime,
    super.description,
    super.status,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',

      dateTime: (data['dateTime'] as Timestamp).toDate(),
      description: data['description'] ?? '',

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
      'description': description,
      'status': status.toString(),
    };
  }
}
