import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_productivity/src/bloc/calendar/calendar_bloc.dart';
import 'package:project_productivity/src/data/event_repository.dart';
import 'package:project_productivity/src/ui/pages/calendar_page/calendar_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static var repo = EventRepository();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'priority list',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (BuildContext context) => CalendarBloc(repository: repo),
        child: CalendarPage(repo: EventRepository()),
      ),
    );
  }
}
