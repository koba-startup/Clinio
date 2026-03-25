import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../core/entities/appointment_entity.dart';

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentEntity> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getAppointmentData(index).dateTime;
  }

  @override
  DateTime getEndTime(int index) {
    // Asumimos que cada cita dura 1 hora por defecto
    return _getAppointmentData(index).dateTime.add(const Duration(hours: 1));
  }

  @override
  String getSubject(int index) {
    final appo = _getAppointmentData(index);
    return '${appo.patientName} - ${appo.description}';
  }

  @override
  Color getColor(int index) {
    final appo = _getAppointmentData(index);
    // Colores según el estado de la cita
    switch (appo.status) {
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.pending:
      return Colors.blueAccent;
    }
  }

  @override
  bool isAllDay(int index) => false;

  AppointmentEntity _getAppointmentData(int index) {
    final dynamic appointment = appointments![index];
    late final AppointmentEntity appointmentData;
    if (appointment is AppointmentEntity) {
      appointmentData = appointment;
    }
    return appointmentData;
  }
}