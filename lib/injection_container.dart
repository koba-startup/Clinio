import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'core/network/network_info.dart';
import 'features/appointments/data/datasource/appointment_remote_data_source.dart';
import 'features/appointments/data/repositories/appointment_repository_impl.dart';
import 'features/appointments/domain/repositories/appointment_repository.dart';
import 'features/appointments/domain/use_cases/add_appointment_usecase.dart';
import 'features/appointments/domain/use_cases/delete_appointments_usecase.dart';
import 'features/appointments/domain/use_cases/get_appointments_usecase.dart';
import 'features/appointments/domain/use_cases/update_appointments_usecase.dart';
import 'features/appointments/presentation/bloc/appointment_bloc.dart';
import 'features/auth/data/datasource/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/use_cases/get_auth_status_usecase.dart';
import 'features/auth/domain/use_cases/login_usecase.dart';
import 'features/auth/domain/use_cases/logout_usecase.dart';
import 'features/auth/domain/use_cases/signup_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/patients/data/datasource/patient_remote_data_source.dart';
import 'features/patients/data/repositories/patient_repository_impl.dart';
import 'features/patients/domain/repositories/patient_repository.dart';
import 'features/patients/domain/use_cases/add_patient_usecase.dart';
import 'features/patients/domain/use_cases/delete_patient_usecase.dart';
import 'features/patients/domain/use_cases/get_patients_usecase.dart';
import 'features/patients/domain/use_cases/update_patient_usecase.dart';
import 'features/patients/presentation/bloc/patient_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features ---------- Auth -----------------

  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getAuthStatusUseCase: sl(),
      signUpUseCase: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthStatusUseCase(sl()));

  //! Features ---------- Patients -----------------
  sl.registerFactory(
    () => PatientBloc(
      getPatientsUseCase: sl(),
      addPatientUseCase: sl(),
      updatePatientUseCase: sl(),
      deletePatientUseCase: sl(),
    ),
  );
  // Repository
  sl.registerLazySingleton<PatientRepository>(
    () => PatientRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PatientRemoteDataSource>(
    () => PatientRemoteDataSourceImpl(sl(),sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPatientsUseCase(sl()));
  sl.registerLazySingleton(() => AddPatientUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePatientUseCase(sl()));
  sl.registerLazySingleton(() => DeletePatientUseCase(sl()));

  //! Features ---------- Appointments -----------------

  sl.registerFactory(() => AppointmentBloc(
    getAppointmentsUseCase: sl(),
    addAppointmentUseCase: sl(),
    updateAppointmentUseCase: sl(),
    deleteAppointmentUseCase: sl(),
  ));
  // Repository
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  // Data sources
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
    () => AppointmentRemoteDataSourceImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAppointmentsUseCase(sl()));
  sl.registerLazySingleton(() => AddAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAppointmentUseCase(sl()));

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => InternetConnection());
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
}
