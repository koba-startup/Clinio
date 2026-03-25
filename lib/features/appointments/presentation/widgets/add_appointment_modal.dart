import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/appointment_entity.dart';
import '../../../../core/entities/patient_entity.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';

class AddAppointmentModal extends StatefulWidget {
  final String dentistId;
  final Function(AppointmentEntity) onSave;

  const AddAppointmentModal({
    super.key,
    required this.dentistId,
    required this.onSave,
  });

  @override
  State<AddAppointmentModal> createState() => _AddAppointmentModalState();
}

class _AddAppointmentModalState extends State<AddAppointmentModal> {
  PatientEntity? _selectedPatient;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Agendar Nueva Cita',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // 1. Selector de Paciente (Usando el estado de PatientBloc)
          BlocBuilder<PatientBloc, PatientState>(
            builder: (context, state) {
              if (state is PatientLoaded) {
                return DropdownButtonFormField<PatientEntity>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Paciente',
                  ),
                  items: state.patients
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedPatient = val),
                );
              }
              return const Text('Cargando pacientes...');
            },
          ),
          const SizedBox(height: 15),

          // 2. Selector de Fecha y Hora
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(_selectedTime.format(context)),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) setState(() => _selectedTime = time);
                  },
                ),
              ),
            ],
          ),

          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Motivo de consulta (opcional)',
            ),
          ),
          const SizedBox(height: 25),

          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
            onPressed: _selectedPatient == null
                ? null
                : () {
                    final finalDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    widget.onSave(
                      AppointmentEntity(
                        id: '',
                        patientId: _selectedPatient!.id,
                        patientName: _selectedPatient!.name,
                        dateTime: finalDateTime,
                        description: _descController.text,
                      ),
                    );
                    Navigator.pop(context);
                  },
            child: const Text('Confirmar Cita'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
