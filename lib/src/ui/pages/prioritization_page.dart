import 'package:flutter/material.dart';
import 'package:project_productivity/src/data/event_repository.dart';
import 'package:project_productivity/src/models/event_model.dart';

class PrioritizationPage extends StatefulWidget {
  const PrioritizationPage({super.key});

  @override
  State<PrioritizationPage> createState() => _PrioritizationPageState();
}

class _PrioritizationPageState extends State<PrioritizationPage> {
  final EventRepository repo = EventRepository();

  List<EventModel> unprioritized = [];
  final Map<int, List<EventModel>> prioritized = {
    1: [], // Must do
    2: [], // Should do
    3: [], // Can do
    4: [], // Won’t do
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await repo.getEventsWithoutPriority();
    print('Unprioritized events: ${events.length}'); 
    setState(() {
      unprioritized = events;
      prioritized.forEach((key, list) => list.clear());
    });
  }

  Future<void> _save() async {
    for (var entry in prioritized.entries) {
      for (var event in entry.value) {
        await repo.updateEvent(
          EventModel(
            id: event.id,
            name: event.name,
            duration: event.duration,
            category: event.category,
            type: event.type,
            startDate: event.startDate,
            deadline: event.deadline,
            subtasks: event.subtasks,
            priority: entry.key,
          ),
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Priorities saved!')),
      );
      Navigator.pop(context, true);
    }
  }

  void _resetAll() {
    setState(() {
      prioritized.forEach((key, list) {
        unprioritized.addAll(list);
        list.clear();
      });
    });
  }

  Widget _buildDraggableChip(EventModel event) {
    return Draggable<EventModel>(
      data: event,
      feedback: Material(
        color: Colors.transparent,
        child: Chip(label: Text(event.name)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Chip(label: Text(event.name)),
      ),
      child: Chip(label: Text(event.name)),
    );
  }

  Widget _buildDragTarget(String label, int priority, Color color) {
    return Expanded(
      child: DragTarget<EventModel>(
        onAccept: (event) {
          setState(() {
            // Remove from other lists if exists
            unprioritized.remove(event);
            prioritized.forEach((_, list) => list.remove(event));
            // Add to target list
            prioritized[priority]!.add(event);
          });
        },
        builder: (context, candidateData, rejectedData) => Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: -8,
                children: prioritized[priority]!.map(_buildDraggableChip).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prioritize Events'),
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: const Text('Reset All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Unprioritized Events', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: unprioritized.map(_buildDraggableChip).toList(),
            ),
          ),
          const Divider(height: 30),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDragTarget('Must Do', 1, Colors.red),
                _buildDragTarget('Should Do', 2, Colors.orange),
                _buildDragTarget('Can Do', 3, Colors.amber),
                _buildDragTarget("Won't Do", 4, Colors.grey),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        tooltip: 'Save Priorities',
        child: const Icon(Icons.save),
      ),
    );
  }
}
