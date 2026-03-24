import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/entities/patient_entity.dart';

class PatientModel extends PatientEntity {
  const PatientModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    super.createdAt,
  });

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
