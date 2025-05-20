import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_bloc.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_event.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_state.dart';
import '../../../data/event_repository.dart';
import '../../../widgets/loading_indicator.dart';
import '../../pages/calendar_page/day_view.dart';
import '../../pages/calendar_page/week_view.dart';
import '../../pages/calendar_page/month_view.dart';

class CalendarPage extends StatelessWidget {
  final EventRepository repo;
  const CalendarPage({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarBloc(repository: repo),
      child: DefaultTabController(
        length: 3,
        initialIndex: 1,
        child: Builder(
          builder: (inner) {
            final bloc = inner.read<CalendarBloc>();
            return Scaffold(
              appBar: AppBar(
                title: const Text('Kalendar'),
                leading: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.pushNamed(inner, '/settings'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => Navigator.pushNamed(inner, '/new_event'),
                  ),
                ],
                bottom: TabBar(
                  onTap: (i) => bloc.add(ChangeView(period: CalendarPeriod.values[i])),
                  tabs: const [
                    Tab(text: 'DAY'),
                    Tab(text: 'WEEK'),
                    Tab(text: 'MONTH'),
                  ],
                ),
              ),
              body: BlocBuilder<CalendarBloc, CalendarState>(
                builder: (context, state) {
                  if (state is CalendarLoading) {
                    return const LoadingIndicator();
                  } else if (state is CalendarError) {
                    return Center(child: Text('Error: \${state.message}'));
                  } else if (state is CalendarLoaded) {
                    print(state.view); print(state.events);
                    return TabBarView(
                      children: [
                        DayView(events: state.events),
                        WeekView(events: state.events),
                        MonthView(events: state.events),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

