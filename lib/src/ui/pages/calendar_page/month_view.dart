import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../models/event_model.dart';
import '../../../data/event_repository.dart';
import '../new_event_page.dart';
import '../../../bloc/calendar/calendar_bloc.dart';
import '../../../bloc/calendar/calendar_event.dart';

class MonthView extends StatelessWidget {
  final List<EventModel> events;
  const MonthView({super.key, required this.events});

  DateTime get _startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime get _endOfMonth {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
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
            final events = await repo.getEventsInRange(tapped.startTime, tapped.endTime);
            final event = events.firstWhere((e) => e.id == id);
            final refresh = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NewEventPage(event: event)),
            );
            if (refresh == true && context.mounted) {
              context.read<CalendarBloc>().add(LoadEvents(
                from: context.read<CalendarBloc>().currentRange.start,
                to: context.read<CalendarBloc>().currentRange.end,
              ));
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
