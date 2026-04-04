import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/entities/patient_entity.dart';
import '../bloc/patient_bloc.dart';
import '../widgets/edit_patient_modal.dart';
import '../pages/patients_page.dart'; // Para reutilizar PatientAvatar

class DetailPatientPage extends StatelessWidget {
  final PatientEntity patient;
  final PatientBloc patientBloc;
  final String dentistId;

  const DetailPatientPage({
    super.key,
    required this.patient,
    required this.patientBloc,
    required this.dentistId,
  });

  String get _initials {
    final parts = patient.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Reutilizamos el BLoC de la lista — sin nueva suscripción a Firestore
    return BlocProvider.value(
      value: patientBloc,
      child: BlocListener<PatientBloc, PatientState>(
        listener: (context, state) {
          if (state is PatientOperationSuccess) {
            // Volvemos a la lista después de editar o eliminar
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Operación realizada con éxito'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is PatientError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del paciente'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => _showEditModal(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Eliminar',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Cabecera con foto ─────────────────────────────────────
                _PatientHeader(patient: patient, initials: _initials),

                // ── Información ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Información de contacto'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        children: [
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'WhatsApp',
                            value: patient.phone,
                          ),
                          if (patient.email != null &&
                              patient.email!.isNotEmpty) ...[
                            const Divider(height: 1),
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'Correo',
                              value: patient.email!,
                            ),
                          ],
                          if (patient.createdAt != null) ...[
                            const Divider(height: 1),
                            _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Registrado',
                              value:
                              '${patient.createdAt!.day}/${patient.createdAt!.month}/${patient.createdAt!.year}',
                            ),
                          ],
                        ],
                      ),

                      if (patient.observations != null &&
                          patient.observations!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle('Observaciones médicas'),
                        const SizedBox(height: 12),
                        _InfoCard(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                patient.observations!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ── Acciones ──────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                              onPressed: () => _showEditModal(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: () => _confirmDelete(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => BlocProvider.value(
        value: patientBloc,
        child: EditPatientModal(
          patient: patient,
          dentistId: dentistId,
          onSave: (updated) {
            patientBloc.add(UpdatePatientRequested(updated, dentistId));
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar paciente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${patient.name}? '
              'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              patientBloc.add(DeletePatientRequested(patient.id, dentistId));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Cabecera con foto ─────────────────────────────────────────────────────────

class _PatientHeader extends StatelessWidget {
  final PatientEntity patient;
  final String initials;

  const _PatientHeader({required this.patient, required this.initials});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.primaryContainer.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Avatar grande — usa el caché de la lista, no descarga de nuevo
          PatientAvatar(
            photoUrl: patient.photoUrl,
            initials: initials,
            radius: 48,
          ),
          const SizedBox(height: 16),
          Text(
            patient.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (patient.email != null && patient.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              patient.email!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Componentes de UI ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}