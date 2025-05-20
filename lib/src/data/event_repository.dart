import 'database/database_provider.dart';
import '../models/event_model.dart';

class EventRepository {
  final DatabaseProvider _dbProvider = DatabaseProvider();

  Future<List<EventModel>> getEventsInRange(DateTime from, DateTime to) async {
    final db = await _dbProvider.database;
    print(from); print(to);
    print(
    await db.query(
      'events'
    ));
    final maps = await db.query(
      'events',
      where: 'start >= ? AND start <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
    );
    return maps.map((m) => EventModel.fromMap(m)).toList();
  }

  Future<int> addEvent(EventModel event) async {
    final db = await _dbProvider.database;
    return db.insert('events', event.toMap());
  }

  Future<int> updateEvent(EventModel event) async {
    final db = await _dbProvider.database;
    return db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await _dbProvider.database;
    return db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
