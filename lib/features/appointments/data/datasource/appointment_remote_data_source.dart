import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Stream<List<AppointmentModel>> getAppointments(String dentistId);

  Future<void> addAppointment(AppointmentModel appointment, String dentistId);

  Future<void> updateAppointment(
    AppointmentModel appointment,
    String dentistId,
  );

  Future<void> deleteAppointment(String appointmentId, String dentistId);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final FirebaseFirestore firestore;

  AppointmentRemoteDataSourceImpl(this.firestore);

  CollectionReference _appoCol(String uid) =>
      firestore.collection('users').doc(uid).collection('appointments');

  @override
  Stream<List<AppointmentModel>> getAppointments(String dentistId) {
    return _appoCol(dentistId)
        .orderBy('dateTime', descending: false) // Orden cronológico
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppointmentModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> addAppointment(
    AppointmentModel appointment,
    String dentistId,
  ) async {
    await _appoCol(dentistId).add(appointment.toFirestore());
  }

  @override
  Future<void> updateAppointment(
    AppointmentModel appointment,
    String dentistId,
  ) async {
    await _appoCol(
      dentistId,
    ).doc(appointment.id).update(appointment.toFirestore());
  }

  @override
  Future<void> deleteAppointment(String appointmentId, String dentistId) async {
    await _appoCol(dentistId).doc(appointmentId).delete();
  }
}
