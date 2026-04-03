import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/entities/patient_entity.dart';

class PatientModel extends PatientEntity {
  const PatientModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    super.photoUrl,
    super.observations,
    super.createdAt,
  });

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      photoUrl: data['photoUrl'],
      observations: data['observations'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'observations': observations,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory PatientModel.fromEntity(PatientEntity entity) {
    return PatientModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      photoUrl: entity.photoUrl,
      observations: entity.observations,
      createdAt: entity.createdAt,
    );
  }

  PatientEntity toEntity() {
    return PatientEntity(
      id: id,
      name: name,
      phone: phone,
      email: email,
      photoUrl: photoUrl,
      observations: observations,
      createdAt: createdAt,
    );
  }
}