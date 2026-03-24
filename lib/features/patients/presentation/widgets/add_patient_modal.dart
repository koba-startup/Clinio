import 'package:flutter/material.dart';

import '../../../../core/entities/patient_entity.dart';

class AddPatientModal extends StatefulWidget {
  final Function(PatientEntity) onSave;

  const AddPatientModal({super.key, required this.onSave});

  @override
  State<AddPatientModal> createState() => _AddPatientModalState();
}

class _AddPatientModalState extends State<AddPatientModal> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nuevo Paciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
              onSaved: (v) => _name = v!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Teléfono (WhatsApp)'),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
              onSaved: (v) => _phone = v!,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  widget.onSave(PatientEntity(id: '', name: _name, phone: _phone));
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar Paciente'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}