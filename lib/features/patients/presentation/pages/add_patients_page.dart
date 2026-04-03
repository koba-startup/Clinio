import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/entities/patient_entity.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/patient_bloc.dart';

// La página se envuelve en su propio BlocProvider para tener
// un BLoC aislado — no comparte estado con la lista de pacientes
class AddPatientsPage extends StatelessWidget {
  const AddPatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state as Authenticated;
    return BlocProvider(
      create: (_) => sl<PatientBloc>(),
      child: _AddPatientsView(dentistId: authState.userId),
    );
  }
}

class _AddPatientsView extends StatefulWidget {
  final String dentistId;

  const _AddPatientsView({required this.dentistId});

  @override
  State<_AddPatientsView> createState() => _AddPatientsViewState();
}

class _AddPatientsViewState extends State<_AddPatientsView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _obsController = TextEditingController();
  final _picker = ImagePicker();

  File? _imageFile;
  bool _isSaving = false;

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
      imageQuality: 85, // Pre-compresión ligera; el datasource hace la compresión real
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // Normaliza a formato +52XXXXXXXXXX para la WhatsApp API
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

    final patient = PatientEntity(
      id: '',
      name: _nameController.text.trim(),
      phone: _normalizePhone(_phoneController.text.trim()),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      observations: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
      // Pasamos el path local — el repository se encarga de subir y obtener la URL
      photoUrl: _imageFile?.path,
      createdAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    context.read<PatientBloc>().add(AddPatientRequested(patient, widget.dentistId));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientOperationSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente guardado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is PatientError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Nuevo Paciente')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Selector de foto ──────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _isSaving ? null : _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                          child: _imageFile == null
                              ? Icon(
                            Icons.person,
                            size: 48,
                            color: colorScheme.onPrimaryContainer,
                          )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
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
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Toca para agregar foto',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
                ),
                const SizedBox(height: 14),

                // ── Teléfono ──────────────────────────────────────────────
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (WhatsApp) *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    helperText: 'Ej: 5512345678 — se usará para recordatorios',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]')),
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

                // ── Botón guardar ─────────────────────────────────────────
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
                      : const Text('Guardar paciente'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}