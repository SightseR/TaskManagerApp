import 'package:project_productivity/src/models/subtask_model.dart';

enum EventType { base, assigned, fixed, deadline }



class EventModel {
  final int? id;
  final String name;
  final DateTime? startDate;
  final DateTime? deadline;
  final Duration duration;
  final List<SubtaskModel>? subtasks;
  final String category;
  final int? priority;
  final EventType type;

  EventModel({
    this.id,
    required this.name,
    this.startDate,
    this.deadline,
    required this.duration,
    this.subtasks,
    required this.category,
    this.priority,
    required this.type,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      duration: Duration(milliseconds: map['duration_ms'] as int),
      subtasks: map['subtasks'] != null
          ? List<SubtaskModel>.from(
              (map['subtasks'] as List).map((item) =>
                  SubtaskModel.fromMap(item as Map<String, dynamic>)))
          : null,
      category: map['category'] as String,
      priority: map['priority'] as int?,
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] as String,
        orElse: () => EventType.base,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      // store duration in milliseconds
      'duration_ms': duration.inMilliseconds,
      if (subtasks != null)
        'subtasks': subtasks!.map((s) => s.toMap()).toList(),
      'category': category,
      if (priority != null) 'priority': priority,
      'type': type.toString().split('.').last,
    };
  }
}
