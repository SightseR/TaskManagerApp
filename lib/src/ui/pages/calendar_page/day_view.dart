import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../models/event_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ✅ needed for context.read
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../models/event_model.dart';
import '../../../data/event_repository.dart'; // ✅ needed to fetch event by ID
import '../new_event_page.dart'; // ✅ needed to navigate to NewEventPage
import '../../../bloc/calendar/calendar_bloc.dart'; // ✅ to dispatch LoadEvents
import '../../../bloc/calendar/calendar_event.dart'; // ✅ to use LoadEvents


class DayView extends StatelessWidget {
  final List<EventModel> events;
  final DateTime date;
  DayView({
    super.key,
    required this.events,
    DateTime? date,
  })  : date = date ?? DateTime.now();
  
  DateTime get _startOfDay {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime get _endOfDay {
    return _startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
  }

  List<EventModel> get _dayEvents {
    return events.where((e) {
      return e.end.isAfter(_startOfDay.subtract(const Duration(seconds: 1))) &&
             e.start.isBefore(_endOfDay.add(const Duration(seconds: 1)));
    }).toList();
  }

  double get _earliestHour {
    if (_dayEvents.isEmpty) return 0;
    final earliest = _dayEvents
        .map((e) => e.start.hour + e.start.minute / 60.0)
        .reduce(math.min);
    return earliest.floorToDouble();
  }

  double get _latestHour {
    if (_dayEvents.isEmpty) return 24;
    final latest = _dayEvents
        .map((e) => e.end.hour + e.end.minute / 60.0)
        .reduce(math.max);
    return latest.ceilToDouble();
  }

  List<Appointment> get _appointments {
    return _dayEvents.map((e) {
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
      view: CalendarView.day,
      dataSource: _DayDataSource(_appointments),
      allowViewNavigation: false,
      allowDragAndDrop: true,
      allowAppointmentResize: false,
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: _earliestHour,
        endHour: _latestHour,
        timeIntervalHeight: 30,
      ),
      firstDayOfWeek: DateTime.monday,
      todayHighlightColor: Theme.of(context).primaryColor,

      // 👇 Handle taps on appointments for editing
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

class _DayDataSource extends CalendarDataSource {
  _DayDataSource(List<Appointment> source) {
    appointments = source;
  }
}
