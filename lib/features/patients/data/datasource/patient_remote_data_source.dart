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
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  PatientRemoteDataSourceImpl(this.firestore, this.storage);

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

  @override
  Future<String?> uploadPatientPhoto(
    File imageFile,
    String dentistId,
    String patientId,
  ) async {
    try {
      // 1. Comprimir a WebP con código nativo — rápido, sin bloquear UI
      //    minWidth/minHeight: la imagen no saldrá más pequeña que esto
      //    quality 80: buen balance tamaño/calidad para fotos de perfil
      //    WebP nativo es ~25-35% más liviano que JPEG a calidad equivalente
      final Uint8List? compressedBytes =
          await FlutterImageCompress.compressWithFile(
            imageFile.absolute.path,
            minWidth: 800,
            minHeight: 800,
            quality: 80,
            format: CompressFormat.webp,
          );

      if (compressedBytes == null) {
        throw Exception('No se pudo comprimir la imagen');
      }

      // 2. Subir a Firebase Storage
      final storageRef = storage.ref().child(
        'users/$dentistId/patients/$patientId/profile.webp',
      );

      final uploadTask = await storageRef.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/webp'),
      );

      // 3. Retornar la URL pública permanente
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al procesar/subir imagen: $e');
    }
  }
}
