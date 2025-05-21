import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_bloc.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_event.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_state.dart';
import 'package:project_productivity/src/ui/pages/calendar_page/day_view.dart';
import 'package:project_productivity/src/ui/pages/calendar_page/month_view.dart';
import 'package:project_productivity/src/ui/pages/calendar_page/week_view.dart';
import 'package:project_productivity/src/widgets/loading_indicator.dart';

class PeriodPager extends StatefulWidget {
  final CalendarPeriod period;
  const PeriodPager({Key? key, required this.period}) : super(key: key);

  @override
  State<PeriodPager> createState() => _PeriodPagerState();
}

class _PeriodPagerState extends State<PeriodPager> {
  static const _initialPage = 10000;
  late final PageController _controller;
  late final DateTime _baseDate;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CalendarBloc>();
    // Basis-Datum für Berechnungen
    _baseDate = bloc.currentRange.start;

    _controller = PageController(initialPage: _initialPage);
    // Initiale Lade-Range senden
    bloc.add(ChangeView(period: widget.period));
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        final bloc = context.read<CalendarBloc>();
        final offset = index - _initialPage;
        DateTime ref;
        switch (widget.period) {
          case CalendarPeriod.day:
            ref = _baseDate.add(Duration(days: offset));
            break;
          case CalendarPeriod.week:
            ref = _baseDate.add(Duration(days: offset * 7));
            break;
          case CalendarPeriod.month:
            final bd = _baseDate;
            ref = DateTime(bd.year, bd.month + offset, bd.day);
            break;
        }
        // Berechne Start/End basierend auf ref und sende
        late DateTime from, to;
        switch (widget.period) {
          case CalendarPeriod.day:
            from = DateTime(ref.year, ref.month, ref.day);
            to = from.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
            break;
          case CalendarPeriod.week:
            final startOfWeek = DateTime(ref.year, ref.month, ref.day)
                .subtract(Duration(days: ref.weekday - DateTime.monday));
            from = startOfWeek;
            to = startOfWeek.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
            break;
          case CalendarPeriod.month:
            from = DateTime(ref.year, ref.month, 1);
            final next = DateTime(ref.year, ref.month + 1, 1);
            to = next.subtract(const Duration(milliseconds: 1));
            break;
        }
        bloc.add(LoadEvents(from: from, to: to));
      },
      itemBuilder: (context, index) {
        return BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            if (state is CalendarLoaded && state.view == widget.period) {
              switch (widget.period) {
                case CalendarPeriod.day:
                  return DayView(events: state.events);
                case CalendarPeriod.week:
                  return WeekView(events: state.events);
                case CalendarPeriod.month:
                  return MonthView(events: state.events);
              }
            }
            return const LoadingIndicator();
          },
        );
      },
    );
  }
}
