import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:project_productivity/src/bloc/calendar/calendar_bloc.dart';
import 'package:project_productivity/src/bloc/theme/theme_cubit.dart';
import 'package:project_productivity/src/data/event_repository.dart';
import 'package:project_productivity/src/ui/pages/calendar_page/calendar_page.dart';
import 'package:project_productivity/src/ui/pages/new_event_page.dart';
import 'package:project_productivity/src/ui/pages/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final repo = EventRepository();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<CalendarBloc>(
          create: (_) => CalendarBloc(repository: repo),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'priority list',
            theme: themeState.themeData,
            routes: {
              '/new_event': (context) => const NewEventPage(),
              '/settings': (context) => const SettingsPage(),
            },
            home: CalendarPage(repo: repo),
          );
        },
      ),
    );
  }
}
