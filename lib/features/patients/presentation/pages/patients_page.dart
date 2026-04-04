import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/entities/patient_entity.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/patient_bloc.dart';

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
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final patient = state.patients[index];
                return _PatientTile(
                  patient: patient,
                  onTap: () {
                    // Pasamos el BLoC activo y los datos — sin nueva petición a Firestore
                    context.push(
                      '/patients/detail',
                      extra: {
                        'patient': patient,
                        'bloc': context.read<PatientBloc>(),
                        'dentistId': dentistId,
                      },
                    );
                  },
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/addPatients'),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ── Tile con avatar lazy ──────────────────────────────────────────────────────

class _PatientTile extends StatelessWidget {
  final PatientEntity patient;
  final VoidCallback onTap;

  const _PatientTile({required this.patient, required this.onTap});

  String get _initials {
    final parts = patient.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: PatientAvatar(
        photoUrl: patient.photoUrl,
        initials: _initials,
        radius: 22,
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

// ── Avatar reutilizable con lazy loading ──────────────────────────────────────
// Exportado para usarlo también en DetailPatientPage

class PatientAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double radius;

  const PatientAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    if (!hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          initials,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      );
    }

    // CachedNetworkImage descarga la foto solo cuando el widget aparece en pantalla
    // y la guarda en disco — las siguientes veces no consume datos de red
    return CachedNetworkImage(
      imageUrl: photoUrl!,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      // Mientras carga: muestra iniciales (sin flash ni spinner molesto)
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          initials,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      ),
      // Si falla la carga: fallback a iniciales silenciosamente
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          initials,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 200),
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
