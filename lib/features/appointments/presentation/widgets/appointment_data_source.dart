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
    final appointment = _getAppointmentData(index);
    return appointment.dateTime.add(Duration(minutes: appointment.durationMinutes));
  }

  @override
  String getSubject(int index) {
    final appo = _getAppointmentData(index);
    return '${appo.patientName} - ${appo.treatment}';
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
      case AppointmentStatus.confirmed:
        return Colors.orange;
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
