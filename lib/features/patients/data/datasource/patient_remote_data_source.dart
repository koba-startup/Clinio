import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient_model.dart';

abstract class PatientRemoteDataSource {
  Stream<List<PatientModel>> getPatients(String dentistId);

  Future<void> addPatient(PatientModel patient, String dentistId);

  Future<void> updatePatient(PatientModel patient, String dentistId);

  Future<void> deletePatient(String patientId, String dentistId);
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final FirebaseFirestore firestore;

  PatientRemoteDataSourceImpl(this.firestore);

  CollectionReference _patientCol(String uid) =>
      firestore.collection('users').doc(uid).collection('patients');

  @override
  Stream<List<PatientModel>> getPatients(String dentistId) {
    return _patientCol(dentistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PatientModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> addPatient(PatientModel patient, String dentistId) async {
    await _patientCol(dentistId).add(patient.toFirestore());
  }

  @override
  Future<void> updatePatient(PatientModel patient, String dentistId) async {
    await _patientCol(dentistId).doc(patient.id).update(patient.toFirestore());
  }

  @override
  Future<void> deletePatient(String patientId, String dentistId) async {
    await _patientCol(dentistId).doc(patientId).delete();
  }
}
