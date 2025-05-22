import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/event_repository.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

enum CalendarPeriod { day, week, month }

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final EventRepository repository;
  CalendarPeriod currentPeriod = CalendarPeriod.week;
  late DateTimeRange currentRange;

  CalendarBloc({required this.repository}) : super(CalendarLoading()) {
    on<ChangeView>(_onChangeView);
    on<LoadEvents>(_onLoadEvents);
    add(LoadEvents());
  }

  void _onChangeView(ChangeView event, Emitter<CalendarState> emit) {
    currentPeriod = event.view;
    add(LoadEvents());
  }


  Future<void> _onLoadEvents(LoadEvents event, Emitter<CalendarState> emit) async {
    emit(CalendarLoading());
    try {
      print('onLoadEvents');
      final assignedEvents = await repository.getAssignedEvents();
      final unassignedEvents = await repository.getUnassignedEvents();
      emit(CalendarLoaded(view: currentPeriod, assignedEvents: assignedEvents, unassignedEvents: unassignedEvents));
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }
}

