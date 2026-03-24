import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/patient_bloc.dart';
import '../widgets/add_patient_modal.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el estado actual de forma segura
    final authState = context.read<AuthBloc>().state;

    // 2. Si por alguna razón no estamos autenticados, mostramos un error o cargando
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dentistId = authState.userId; // Usamos el ID del estado autenticado
    return BlocProvider(
      create: (context) =>
          sl<PatientBloc>()..add(GetPatientsStarted(dentistId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Mis Pacientes')),
        body: BlocBuilder<PatientBloc, PatientState>(
          builder: (context, state) {
            if (state is PatientLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PatientLoaded) {
              if (state.patients.isEmpty) {
                return const Center(
                  child: Text('Aún no tienes pacientes registrados.'),
                );
              }
              return ListView.builder(
                itemCount: state.patients.length,
                itemBuilder: (context, index) {
                  final patient = state.patients[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(patient.name),
                    subtitle: Text(patient.phone),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      /* Ver detalle próximamente */
                    },
                  );
                },
              );
            } else if (state is PatientError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _showAddPatientForm(context, dentistId),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  void _showAddPatientForm(BuildContext context, String dentistId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddPatientModal(
        onSave: (newPatient) {
          context.read<PatientBloc>().add(
            AddPatientRequested(newPatient, dentistId),
          );
        },
      ),
    );
  }
}
