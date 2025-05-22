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
  final List<EventModel> assignedEvents;
  final List<EventModel> unassignedEvents;
  final DateTime date;

  WeekView({
    super.key,
    required this.assignedEvents,
    required this.unassignedEvents,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  DateTime get _startOfWeek {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - DateTime.monday));
  }

  DateTime get _endOfWeek {
    return _startOfWeek.add(const Duration(days: 7));
  }

  List<EventModel> get _weekEvents {
    return assignedEvents.where((e) {
      return !e.startDate!.isBefore(_startOfWeek) && e.startDate!.isBefore(_endOfWeek);
    }).toList();
  }

  double get _earliestStartHour {
    if (_weekEvents.isEmpty) return 0;
    final mins = _weekEvents
        .map((e) => e.startDate!.hour + e.startDate!.minute / 60.0)
        .reduce(math.min);
    return mins.floorToDouble();
  }

  double get _latestEndHour {
    if (_weekEvents.isEmpty) return 24;
    final maxs = _weekEvents
        .map((e) => e.startDate!.add(e.duration).hour +
            e.startDate!.add(e.duration).minute / 60.0)
        .reduce(math.max);
    return maxs.ceilToDouble();
  }

  Color _getColorForPriority(int? priority) {
    switch (priority) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _weekEvents.map((e) {
      final start = e.startDate!;
      final end = start.add(e.duration);
      return Appointment(
        startTime: start,
        endTime: end,
        subject: e.name,
        notes: e.id.toString(),
        color: _getColorForPriority(e.priority), // ✅ Color by priority
      );
    }).toList();

    return SfCalendar(
      view: CalendarView.week,
      firstDayOfWeek: 1,
      controller: CalendarController(),
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
