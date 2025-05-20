import 'package:flutter/material.dart';
import 'package:project_productivity/src/data/event_repository.dart';
import 'package:project_productivity/src/ui/pages/calendar_page/calendar_page.dart';

class AppRouter {
  static const calendar = '/';
  static const newEvent = '/new_event';
  static const settings = '/settings';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case calendar:
        return MaterialPageRoute(
          builder: (_) => CalendarPage(repo: EventRepository()),
        );
      // case newEvent:
      //   return MaterialPageRoute(
      //     builder: (_) => const NewEventPage(),
      //   );
      // case settings:
      //   return MaterialPageRoute(
      //     builder: (_) => const SettingsPage(),
      //   );
      default:
        return null;
    }
  }
}

