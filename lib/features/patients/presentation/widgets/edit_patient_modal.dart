import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/entities/patient_entity.dart';
import '../bloc/patient_bloc.dart';

class EditPatientModal extends StatefulWidget {
  final PatientEntity patient;
  final String dentistId;
  final Function(PatientEntity) onSave;

  const EditPatientModal({
    super.key,
    required this.patient,
    required this.dentistId,
    required this.onSave,
  });

  @override
  State<EditPatientModal> createState() => _EditPatientModalState();
}

class _EditPatientModalState extends State<EditPatientModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  late CountryCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _emailController = TextEditingController(text: widget.patient.email ?? '');

    // Detectar país del teléfono existente
    final phone = widget.patient.phone;
    if (phone.startsWith('+1') ||
        (phone.startsWith('1') && phone.length == 11)) {
      _selectedCountry = CountryCode.us;
    } else {
      _selectedCountry = CountryCode.mx;
    }
    // _phoneController lo inicializa PhoneField via initialPhone
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updated = PatientEntity(
      id: widget.patient.id,
      name: _nameController.text.trim(),
      phone: normalizePhoneWithCode(
        _phoneController.text.trim(),
        _selectedCountry,
      ),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      createdAt: widget.patient.createdAt,
    );

    setState(() => _isSaving = true);
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
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
                'Editar Paciente',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

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

              PhoneField(
                controller: _phoneController,
                enabled: !_isSaving,
                initialPhone: widget.patient.phone,
                // ← detecta y limpia el código automáticamente
                onCountryChanged: (country) =>
                    setState(() => _selectedCountry = country),
              ),
              const SizedBox(height: 12),

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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
