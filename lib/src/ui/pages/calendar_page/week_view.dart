import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../models/event_model.dart';

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
    final dataSource = _EventDataSource(_weekEvents);

    return SfCalendar(
      view: CalendarView.week,
      firstDayOfWeek: 1,
      dataSource: dataSource,
      timeSlotViewSettings: TimeSlotViewSettings(
        timeRulerSize: -1,
        startHour: 
        math.min(8, _earliestStartHour),
        endHour: 
        math.max(16, _latestEndHour),
      ),
      showDatePickerButton: true,
    );
  }
}

class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<EventModel> source) {
    appointments = source.map((e) {
      return Appointment(
        startTime: e.start,
        endTime: e.end,
        subject: e.title,
      );
    }).toList();
  }
}
