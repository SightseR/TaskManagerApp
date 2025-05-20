import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventListTile extends StatelessWidget {
  final EventModel event;
  const EventListTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final start = event.start;
    final end = event.end;
    final timeRange =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'
        ' - '
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    return ListTile(
      title: Text(event.title),
      subtitle: Text(timeRange),
    );
  }
}
