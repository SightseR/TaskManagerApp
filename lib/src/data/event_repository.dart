import 'package:sqflite/sqflite.dart';
import 'database/database_provider.dart';
import '../models/event_model.dart';
import '../models/subtask_model.dart';

class EventRepository {
  final DatabaseProvider _dbProvider = DatabaseProvider();

  /// Get all events that have both a startDate and a priority assigned
  Future<List<EventModel>> getAssignedEvents() async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'events',
      where: 'start_date IS NOT NULL AND priority IS NOT NULL',
    );
    return _mapEventRows(rows, db);
  }

  /// Get all events without any priority set
  Future<List<EventModel>> getEventsWithoutPriority() async {
    final db = await _dbProvider.database;
    final rows = await db.query('events', where: 'priority IS NULL');
    return _mapEventRows(rows, db);
  }

  /// Get all events without a startDate but with a priority (unassigned)
  Future<List<EventModel>> getUnassignedEvents() async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'events',
      where: 'start_date IS NULL AND priority IS NOT NULL',
    );
    print(rows);
    print(await db.query(
      'events'
    ));
    return _mapEventRows(rows, db);
  }

  /// Helper to map DB rows (including subtasks) to EventModel instances
  Future<List<EventModel>> _mapEventRows(
    List<Map<String, dynamic>> rows,
    Database db,
  ) async {
    final events = <EventModel>[];

    for (final row in rows) {
      // Load subtasks for this event (will be empty for fixed events)
      final subtaskRows = await db.query(
        'subtasks',
        where: 'event_id = ?',
        whereArgs: [row['id']],
      );

      // Map each DB row into the shape SubtaskModel.fromMap expects
      final subtasks =
          subtaskRows.map((m) {
            return SubtaskModel.fromMap({
              'name': m['name'] as String,
              'duration': m['duration_ms'] as int,
              'startDate': m['start_date'] as String,
            });
          }).toList();

      // Combine row data with the serialized subtasks list
      final data = Map<String, dynamic>.from(row);
      if (subtasks.isNotEmpty) {
        data['subtasks'] = subtasks.map((s) => s.toMap()).toList();
      }

      events.add(EventModel.fromMap(data));
    }

    return events;
  }

  /// Insert new event plus any subtasks, returns the new event id.
  Future<int> addEvent(EventModel event) async {
    final db = await _dbProvider.database;
    return await db.transaction<int>((txn) async {
      // Determine discriminator type
      String type;
      if (event.priority != null) {
        type = 'assigned';
      } else if (event.startDate != null && event.deadline == null) {
        type = 'fixed';
      } else if (event.deadline != null && event.startDate == null) {
        type = 'deadline';
      } else {
        type = 'base';
      }

      // Insert main event row
      final id = await txn.insert('events', {
        'name': event.name,
        'category': event.category,
        'start_date': event.startDate?.toIso8601String(),
        'deadline': event.deadline?.toIso8601String(),
        'duration_ms': event.duration.inMilliseconds,
        'priority': event.priority,
        'type': type,
      });

      // Insert subtasks if any
      if (event.subtasks != null) {
        for (final st in event.subtasks!) {
          await txn.insert('subtasks', {
            'event_id': id,
            'name': st.name,
            'duration_ms': st.duration.inMilliseconds,
          });
        }
      }
      return id;
    });
  }

  /// Update event + subtasks. Overwrites existing subtasks.
  Future<void> updateEvent(EventModel event) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      // Determine updated discriminator type
      String type;
      if (event.priority != null) {
        type = 'assigned';
      } else if (event.startDate != null && event.deadline == null) {
        type = 'fixed';
      } else if (event.deadline != null && event.startDate == null) {
        type = 'deadline';
      } else {
        type = 'base';
      }

      // Update main event row
      await txn.update(
        'events',
        {
          'name': event.name,
          'category': event.category,
          'start_date': event.startDate?.toIso8601String(),
          'deadline': event.deadline?.toIso8601String(),
          'duration_ms': event.duration.inMilliseconds,
          'priority': event.priority,
          'type': type,
        },
        where: 'id = ?',
        whereArgs: [event.id],
      );

      // Remove old subtasks
      await txn.delete(
        'subtasks',
        where: 'event_id = ?',
        whereArgs: [event.id],
      );

      // Insert new subtasks if any
      if (event.subtasks != null) {
        for (final st in event.subtasks!) {
          await txn.insert('subtasks', {
            'event_id': event.id,
            'name': st.name,
            'duration_ms': st.duration.inMilliseconds,
          });
        }
      }
    });
  }

  /// Delete event; subtasks cascade automatically.
  Future<void> deleteEvent(int id) async {
    final db = await _dbProvider.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
