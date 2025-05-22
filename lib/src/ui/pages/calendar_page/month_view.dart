import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_productivity/src/widgets/event_list_tile.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../models/event_model.dart';
import '../../../data/event_repository.dart';
import '../new_event_page.dart';
import '../../../bloc/calendar/calendar_bloc.dart';
import '../../../bloc/calendar/calendar_event.dart';

class MonthView extends StatelessWidget {
  final List<EventModel> assignedEvents;
  final List<EventModel> unassignedEvents;
  final DateTime date;

  MonthView({
    super.key,
    required this.assignedEvents,
    required this.unassignedEvents,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  DateTime get _startOfMonth => DateTime(date.year, date.month, 1);

  DateTime get _endOfMonth {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(seconds: 1));
  }

  List<EventModel> get _monthEvents {
    return assignedEvents.where((e) {
      final start = e.startDate!;
      final end = start.add(e.duration);
      return end.isAfter(_startOfMonth.subtract(const Duration(seconds: 1))) &&
             start.isBefore(_endOfMonth.add(const Duration(seconds: 1)));
    }).toList();
  }
  



  

  List<Appointment> _getAppointments() {
    return assignedEvents.map((e) {
      final start = e.startDate!;
      final end = start.add(e.duration);
      return Appointment(
        startTime: start,
        endTime: end,
        subject: e.name,
        color: priorityColor(e.priority),
        notes: e.id.toString(),
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
      onTap: (CalendarTapDetails details) async {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          final tapped = details.appointments!.first;
          final id = int.tryParse(tapped.notes ?? '');
          if (id != null) {
            final repo = EventRepository();
            final events = await repo.getAssignedEvents();
            final event = events.firstWhere((e) => e.id == id);
            final refresh = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NewEventPage(event: event)),
            );
            if (refresh == true && context.mounted) {
              context.read<CalendarBloc>().add(LoadEvents());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changes applied')),
              );
            }
          }
        }
      },
    );
  }
}

class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}
