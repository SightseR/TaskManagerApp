import '../../models/event_model.dart';
import 'calendar_bloc.dart';

abstract class CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final CalendarPeriod view;
  final List<EventModel> assignedEvents;
  final List<EventModel> unassignedEvents;

  CalendarLoaded({
    required this.view,
    required this.assignedEvents,
    required this.unassignedEvents,
  });
}

class CalendarError extends CalendarState {
  final String message;
  CalendarError(this.message);
}
