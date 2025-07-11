import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventListTile extends StatelessWidget {
  final EventModel event;
  const EventListTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final duration =
        'd: ${event.duration.inHours} h; dl: ${event.deadline!.month}:${event.deadline!.day}';

    return ListTile(
      tileColor: priorityColor(event.priority),
      title: Text(event.name),
      subtitle: Text(duration),
    );
  }
}

Color priorityColor(int? priority) {
  switch (priority) {
    case 1:
      return Colors.redAccent;
    case 2:
      return Colors.orangeAccent;
    case 3:
      return Colors.amber;
    case 4:
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}
