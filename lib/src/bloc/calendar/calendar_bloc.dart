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
    on<NextPeriod>(_onNextPeriod);
    on<PreviousPeriod>(_onPreviousPeriod);
    on<LoadEvents>(_onLoadEvents);

    currentRange = _calculateRange(DateTime.now(), currentPeriod);
    add(LoadEvents(from: currentRange.start, to: currentRange.end));
  }

  void _onChangeView(ChangeView event, Emitter<CalendarState> emit) {
    currentPeriod = event.period;
    currentRange = _calculateRange(DateTime.now(), currentPeriod);
    add(LoadEvents(from: currentRange.start, to: currentRange.end));
  }

  void _onNextPeriod(NextPeriod event, Emitter<CalendarState> emit) {
    DateTime ref;
    switch (currentPeriod) {
      case CalendarPeriod.day:
        ref = currentRange.start.add(const Duration(days: 1));
        break;
      case CalendarPeriod.week:
        ref = currentRange.start.add(const Duration(days: 7));
        break;
      case CalendarPeriod.month:
        final d = currentRange.start;
        ref = DateTime(d.year, d.month + 1, d.day);
        break;
    }
    currentRange = _calculateRange(ref, currentPeriod);
    add(LoadEvents(from: currentRange.start, to: currentRange.end));
  }

  void _onPreviousPeriod(PreviousPeriod event, Emitter<CalendarState> emit) {
    DateTime ref;
    switch (currentPeriod) {
      case CalendarPeriod.day:
        ref = currentRange.start.subtract(const Duration(days: 1));
        break;
      case CalendarPeriod.week:
        ref = currentRange.start.subtract(const Duration(days: 7));
        break;
      case CalendarPeriod.month:
        final d = currentRange.start;
        ref = DateTime(d.year, d.month - 1, d.day);
        break;
    }
    currentRange = _calculateRange(ref, currentPeriod);
    add(LoadEvents(from: currentRange.start, to: currentRange.end));
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<CalendarState> emit) async {
    emit(CalendarLoading());
    try {
      final events = await repository.getEventsInRange(event.from, event.to);
      emit(CalendarLoaded(view: currentPeriod, events: events));
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }

  DateTimeRange _calculateRange(DateTime ref, CalendarPeriod period) {
    switch (period) {
      case CalendarPeriod.day:
        final start = DateTime(ref.year, ref.month, ref.day);
        final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case CalendarPeriod.week:
        final start = DateTime(ref.year, ref.month, ref.day)
            .subtract(Duration(days: ref.weekday - DateTime.monday));
        final end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case CalendarPeriod.month:
        final start = DateTime(ref.year, ref.month, 1);
        final next = DateTime(ref.year, ref.month + 1, 1);
        final end = next.subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }
}

