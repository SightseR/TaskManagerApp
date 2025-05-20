import 'package:equatable/equatable.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_bloc.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();
  @override
  List<Object?> get props => [];
}

class ChangeView extends CalendarEvent {
  final CalendarPeriod period;
  const ChangeView({required this.period});

  @override
  List<Object?> get props => [period];
}

class LoadEvents extends CalendarEvent {
  final DateTime from;
  final DateTime to;
  const LoadEvents({required this.from, required this.to});

  @override
  List<Object?> get props => [from, to];
}

class NextPeriod extends CalendarEvent {}
class PreviousPeriod extends CalendarEvent {}
