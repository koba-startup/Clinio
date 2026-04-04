import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/patient_model.dart';

abstract class PatientRemoteDataSource {
  Stream<List<PatientModel>> getPatients(String dentistId);

  Future<void> addPatient(PatientModel patient, String dentistId);

  Future<void> updatePatient(PatientModel patient, String dentistId);

  Future<void> deletePatient(String patientId, String dentistId);

  Future<String?> uploadPatientPhoto(
    File imageFile,
    String dentistId,
    String patientId,
  );

  Future<void> deletePatientPhoto(String dentistId, String patientId);

  // Genera un ID de Firestore antes de guardar — clave para sincronizar con Storage
  String generatePatientId(String dentistId);
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  PatientRemoteDataSourceImpl(this.firestore, this.storage);

  CollectionReference _patientCol(String uid) =>
      firestore.collection('users').doc(uid).collection('patients');

  Reference _photoRef(String dentistId, String patientId) =>
      storage.ref().child('users/$dentistId/patients/$patientId/profile.webp');

  // Genera el ID que Firestore usará — permite usarlo en Storage ANTES de guardar
  @override
  String generatePatientId(String dentistId) => _patientCol(dentistId).doc().id;

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
    // set() con ID explícito en lugar de add() con ID auto-generado
    // Así el ID del documento siempre coincide con el path de la foto en Storage
    await _patientCol(dentistId).doc(patient.id).set(patient.toFirestore());
  }

  @override
  Future<void> updatePatient(PatientModel patient, String dentistId) async {
    await _patientCol(dentistId).doc(patient.id).update(patient.toFirestore());
  }

  @override
  Future<void> deletePatient(String patientId, String dentistId) async {
    await deletePatientPhoto(dentistId, patientId);
    await _patientCol(dentistId).doc(patientId).delete();
  }

  @override
  Future<String?> uploadPatientPhoto(
    File imageFile,
    String dentistId,
    String patientId,
  ) async {
    final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 800,
      minHeight: 800,
      quality: 80,
      format: CompressFormat.webp,
    );

    if (compressed == null) throw Exception('No se pudo comprimir la imagen');

    final uploadTask = await _photoRef(
      dentistId,
      patientId,
    ).putData(compressed, SettableMetadata(contentType: 'image/webp'));

    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Future<void> deletePatientPhoto(String dentistId, String patientId) async {
    try {
      await _photoRef(dentistId, patientId).delete();
    } on FirebaseException catch (e) {
      // object-not-found = el paciente nunca tuvo foto, no es error real
      if (e.code != 'object-not-found') {
        // Cualquier otro error (permisos, red) sí debe propagarse
        rethrow;
      }
    }
  }
}
