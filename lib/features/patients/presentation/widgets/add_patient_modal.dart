import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/entities/patient_entity.dart';
import '../bloc/patient_bloc.dart';

class AddPatientModal extends StatefulWidget {
  final String dentistId;
  final Function(PatientEntity) onSave;

  const AddPatientModal({
    super.key,
    required this.dentistId,
    required this.onSave,
  });

  @override
  State<AddPatientModal> createState() => _AddPatientModalState();
}

class _AddPatientModalState extends State<AddPatientModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  CountryCode _selectedCountry = CountryCode.mx;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final patient = PatientEntity(
      id: '',
      name: _nameController.text.trim(),
      phone: normalizePhoneWithCode(_phoneController.text.trim(), _selectedCountry),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    widget.onSave(patient);
  }

  @override
  Widget build(BuildContext context) {
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
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar visual
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Nuevo Paciente',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es requerido'
                    : null,
              ),
              const SizedBox(height: 12),

              // Teléfono - crítico para WhatsApp
              PhoneField(
                controller: _phoneController,
                enabled: !_isSaving,
                onCountryChanged: (country) => setState(() => _selectedCountry = country),
              ),
              const SizedBox(height: 12),

              // Email - opcional
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico (opcional)',
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
              const SizedBox(height: 24),

              // Botón guardar
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
                    : const Text('Guardar Paciente'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
