import 'package:equatable/equatable.dart';

class PatientEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final DateTime? createdAt;

  const PatientEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, phone, email, createdAt];
}