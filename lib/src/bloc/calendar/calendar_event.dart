import 'package:equatable/equatable.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_bloc.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();
  @override
  List<Object?> get props => [];
}

class ChangeView extends CalendarEvent {
  final CalendarPeriod view;
  const ChangeView({required this.view});

  @override
  List<Object?> get props => [view];
}

class LoadEvents extends CalendarEvent {
  const LoadEvents();

  @override
  List<Object?> get props => [];
}

