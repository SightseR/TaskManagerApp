import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventListTile extends StatelessWidget {
  final EventModel event;
  const EventListTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final duration = 'd: ${event.duration.inHours} h; dl: ${event.deadline!.month}:${event.deadline!.day}';

    return ListTile(
      tileColor: priorityColor(event.priority),
      title: Text(event.name),
      subtitle: Text(duration),
    );
  }
}

    Color priorityColor(int? priority) {
      switch (priority) {
        case 0:
          return Colors.red.shade200; // Must
        case 1:
          return Colors.orange.shade200; // Should
        case 2:
          return Colors.yellow.shade200; // Could
        case 3:
          return Colors.grey.shade400; // Won’t
        default:
          return Colors.white; // no priority
      }
    }