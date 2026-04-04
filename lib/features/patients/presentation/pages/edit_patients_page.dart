import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/entities/patient_entity.dart';
import '../bloc/patient_bloc.dart';

class EditPatientPage extends StatelessWidget {
  final PatientEntity patient;
  final PatientBloc patientBloc;
  final String dentistId;

  const EditPatientPage({
    super.key,
    required this.patient,
    required this.patientBloc,
    required this.dentistId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: patientBloc,
      child: _EditPatientView(patient: patient, dentistId: dentistId),
    );
  }
}

class _EditPatientView extends StatefulWidget {
  final PatientEntity patient;
  final String dentistId;

  const _EditPatientView({required this.patient, required this.dentistId});

  @override
  State<_EditPatientView> createState() => _EditPatientViewState();
}

class _EditPatientViewState extends State<_EditPatientView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _obsController;
  final _picker = ImagePicker();

  // null = sin foto | String que empieza con '/' = path local nuevo
  // String que empieza con 'http' = URL existente de Firebase
  // _photoRemoved = true significa que el usuario eligió quitar la foto
  String? _photoUrl;
  bool _photoRemoved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _phoneController = TextEditingController(text: widget.patient.phone);
    _emailController = TextEditingController(text: widget.patient.email ?? '');
    _obsController = TextEditingController(
      text: widget.patient.observations ?? '',
    );
    _photoUrl = widget.patient.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _photoUrl = pickedFile.path;
        _photoRemoved = false;
      });
    }
  }

  void _removePhoto() {
    setState(() {
      _photoUrl = null;
      _photoRemoved = true;
    });
  }

  String _normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+52')) return cleaned;
    if (cleaned.startsWith('52') && cleaned.length == 12) return '+$cleaned';
    if (cleaned.length == 10) return '+52$cleaned';
    return cleaned;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es requerido';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (!RegExp(r'^\d{10}$').hasMatch(cleaned) &&
        !RegExp(r'^52\d{10}$').hasMatch(cleaned)) {
      return 'Ingresa un número válido de 10 dígitos';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Si el usuario eliminó la foto, pasamos null para que el repository la borre de Storage
    // Si hay un path local, el repository lo sube y reemplaza la anterior
    // Si es una URL http, no cambió nada — se queda igual
    final String? finalPhotoUrl = _photoRemoved ? null : _photoUrl;

    final updated = PatientEntity(
      id: widget.patient.id,
      name: _nameController.text.trim(),
      phone: _normalizePhone(_phoneController.text.trim()),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      observations: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
      photoUrl: finalPhotoUrl,
      createdAt: widget.patient.createdAt,
    );

    setState(() => _isSaving = true);
    context.read<PatientBloc>().add(
      UpdatePatientRequested(updated, widget.dentistId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientOperationSuccess) {
          Navigator.pop(context);
        } else if (state is PatientError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar paciente'),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Foto de perfil ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isSaving ? null : _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            _buildPhotoPreview(colorScheme),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Opción de quitar foto (solo si tiene una)
                      if (_photoUrl != null && !_photoRemoved)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Quitar foto'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _isSaving ? null : _removePhoto,
                        )
                      else
                        Text(
                          'Toca para agregar foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Nombre ────────────────────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es requerido'
                      : null,
                ),
                const SizedBox(height: 14),

                // ── Teléfono ──────────────────────────────────────────────
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (WhatsApp) *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    helperText: 'Ej: 5512345678',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[\d\s\-\(\)\+]'),
                    ),
                  ],
                  validator: _validatePhone,
                ),
                const SizedBox(height: 14),

                // ── Email ─────────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Observaciones ─────────────────────────────────────────
                TextFormField(
                  controller: _obsController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones médicas',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.notes_outlined),
                    ),
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(ColorScheme colorScheme) {
    // Caso 1: usuario eligió quitar la foto → avatar con iniciales
    if (_photoRemoved || _photoUrl == null) {
      return _initialsAvatar(colorScheme);
    }

    // Caso 2: path local → imagen del dispositivo aún no subida
    if (_photoUrl!.startsWith('/')) {
      return CircleAvatar(
        radius: 52,
        backgroundImage: FileImage(File(_photoUrl!)),
      );
    }

    // Caso 3: URL de Firebase → imagen en caché de CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: _photoUrl!,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: 52, backgroundImage: imageProvider),
      placeholder: (context, url) => _initialsAvatar(colorScheme),
      errorWidget: (context, url, error) => _initialsAvatar(colorScheme),
    );
  }

  Widget _initialsAvatar(ColorScheme colorScheme) {
    final parts = widget.patient.name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();

    return CircleAvatar(
      radius: 52,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
      ),
    );
  }
}
