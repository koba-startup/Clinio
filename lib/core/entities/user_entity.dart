import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? clinicName;
  final DateTime? createdAt;
  final String plan;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.clinicName,
    this.createdAt,
    this.plan = 'free',
  });

  @override
  List<Object?> get props => [id, email, name, phone, clinicName, createdAt, plan];
}