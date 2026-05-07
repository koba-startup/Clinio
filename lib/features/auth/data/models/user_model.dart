import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../../../core/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.phone,
    super.clinicName,
    super.createdAt,
    super.plan,
  });

  factory UserModel.fromFirebase(firebase.User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      phone: data['phone'],
      clinicName: data['clinicName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      plan: data['plan'] ?? 'free',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'clinicName': clinicName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'plan': plan,
    };
  }

  // Mantener toJson por compatibilidad
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name};
  }
}
