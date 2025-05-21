import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../models/event_model.dart';

class MonthView extends StatelessWidget {
  final List<EventModel> events;
  final DateTime date;
  MonthView({
    super.key,
    required this.events,
    DateTime? date,
  })  : date = date ?? DateTime.now();

  DateTime get _startOfMonth {

    return DateTime(date.year, date.month, 1);
  }
  DateTime get _endOfMonth {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(seconds: 1));
  }

  List<EventModel> get _monthEvents {
    return events.where((e) {
      return e.end.isAfter(_startOfMonth.subtract(const Duration(seconds: 1))) &&
             e.start.isBefore(_endOfMonth.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<Appointment> _getAppointments() {
    return _monthEvents.map((e) {
      return Appointment(
        startTime: e.start,
        endTime: e.end,
        subject: e.title,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      view: CalendarView.month,
      firstDayOfWeek: 1, 
      dataSource: _EventDataSource(_getAppointments()),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        appointmentDisplayCount: 4, 
        showAgenda: false,         
      ),
    );
  }
}

class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}
