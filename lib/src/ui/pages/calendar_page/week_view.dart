import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../models/event_model.dart';
import '../../../data/event_repository.dart';
import '../new_event_page.dart';
import '../../../bloc/calendar/calendar_bloc.dart';
import '../../../bloc/calendar/calendar_event.dart';

class WeekView extends StatelessWidget {
  final List<EventModel> events;
  final DateTime date;
  WeekView({
    super.key,
    required this.events,
    DateTime? date,
  })  : date = date ?? DateTime.now();

  DateTime get _startOfWeek {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - DateTime.monday));
  }

  DateTime get _endOfWeek {
    return _startOfWeek.add(const Duration(days: 7));
  }

  List<EventModel> get _weekEvents {
    return events.where((e) {
      return !e.start.isBefore(_startOfWeek) && e.start.isBefore(_endOfWeek);
    }).toList();
  }

  double get _earliestStartHour {
    if (_weekEvents.isEmpty) return 0;
    final mins = _weekEvents
        .map((e) => e.start.hour + e.start.minute / 60.0)
        .reduce(math.min);
    return mins.floorToDouble();
  }

  double get _latestEndHour {
    if (_weekEvents.isEmpty) return 24;
    final maxs = _weekEvents
        .map((e) => e.end.hour + e.end.minute / 60.0)
        .reduce(math.max);
    return maxs.ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _weekEvents.map((e) {
      return Appointment(
        startTime: e.start,
        endTime: e.end,
        subject: e.title,
        notes: e.id.toString(),
      );
    }).toList();

    return SfCalendar(
      view: CalendarView.week,
      firstDayOfWeek: 1,
      dataSource: _EventDataSource(appointments),
      timeSlotViewSettings: TimeSlotViewSettings(
        timeRulerSize: -1,
        startHour: math.min(8, _earliestStartHour),
        endHour: math.max(16, _latestEndHour),
      ),
      showDatePickerButton: true,
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
