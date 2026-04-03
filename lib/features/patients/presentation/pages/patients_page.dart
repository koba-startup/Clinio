import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/entities/patient_entity.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/patient_bloc.dart';
import '../widgets/edit_patient_model.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final dentistId = authState.userId;

    return BlocProvider(
      create: (context) =>
          sl<PatientBloc>()..add(GetPatientsStarted(dentistId)),
      child: _PatientsView(dentistId: dentistId),
    );
  }
}

class _PatientsView extends StatelessWidget {
  final String dentistId;

  const _PatientsView({required this.dentistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pacientes')),
      body: BlocConsumer<PatientBloc, PatientState>(
        listener: (context, state) {
          if (state is PatientOperationSuccess) {
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
        builder: (context, state) {
          if (state is PatientLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<PatientBloc>().add(
                      GetPatientsStarted(dentistId),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is PatientLoaded) {
            if (state.patients.isEmpty) {
              return _EmptyState(onAdd: () => context.push('/addPatients'));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.patients.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final patient = state.patients[index];
                return _PatientTile(
                  patient: patient,
                  dentistId: dentistId,
                  onTap: () => _showDetailSheet(context, patient, dentistId),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () => context.push('/addPatients'),
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context,
    PatientEntity patient,
    String dentistId,
  ) {
    final patientBloc = context.read<PatientBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: patientBloc,
        child: _PatientDetailSheet(
          patient: patient,
          dentistId: dentistId,
          onEdit: () {
            Navigator.pop(sheetContext);
            _showEditModal(context, patient);
          },
          onDelete: () {
            Navigator.pop(sheetContext);
            _confirmDelete(context, patient, dentistId);
          },
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, PatientEntity patient) {
    final patientBloc = context.read<PatientBloc>();
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

  void _confirmDelete(
    BuildContext context,
    PatientEntity patient,
    String dentistId,
  ) {
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
              context.read<PatientBloc>().add(
                DeletePatientRequested(patient.id, dentistId),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Tile del paciente en la lista ─────────────────────────────────────────────

class _PatientTile extends StatelessWidget {
  final PatientEntity patient;
  final String dentistId;
  final VoidCallback onTap;

  const _PatientTile({
    required this.patient,
    required this.dentistId,
    required this.onTap,
  });

  // Genera las iniciales del nombre para el avatar
  String get _initials {
    final parts = patient.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          _initials,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        patient.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(patient.phone),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ── Panel de detalles del paciente ────────────────────────────────────────────

class _PatientDetailSheet extends StatelessWidget {
  final PatientEntity patient;
  final String dentistId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PatientDetailSheet({
    required this.patient,
    required this.dentistId,
    required this.onEdit,
    required this.onDelete,
  });

  String get _initials {
    final parts = patient.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar grande
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              _initials,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            patient.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (patient.email != null && patient.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(patient.email!, style: TextStyle(color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 20),

          // Info cards
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'WhatsApp',
            value: patient.phone,
          ),
          if (patient.createdAt != null)
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Registrado',
              value:
                  '${patient.createdAt!.day}/${patient.createdAt!.month}/${patient.createdAt!.year}',
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // Acciones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes pacientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer paciente para comenzar a agendar citas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar primer paciente'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
