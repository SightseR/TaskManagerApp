import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._internal();
  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();

  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'events.db'),
      version: 3,
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Main events table with type discriminator
      await db.execute('''
        CREATE TABLE events(
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          name         TEXT    NOT NULL,
          category     TEXT    NOT NULL,
          start_date   TEXT,               -- ISO8601 or DATETIME, optional
          deadline     TEXT,               -- optional
          duration_ms  INTEGER NOT NULL,
          priority     INTEGER,
          type         TEXT    NOT NULL    CHECK(type IN ('base','assigned','fixed','deadline')),
          -- type‐specific non‐null constraints
          CHECK(CASE WHEN type = 'assigned' THEN priority   IS NOT NULL ELSE TRUE END),
          CHECK(CASE WHEN type = 'fixed'    THEN start_date IS NOT NULL ELSE TRUE END),
          CHECK(CASE WHEN type = 'deadline' THEN deadline   IS NOT NULL ELSE TRUE END)
        )
      ''');

      await db.execute('''
        CREATE TABLE subtasks(
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id     INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
          name         TEXT    NOT NULL,
          duration_ms  INTEGER NOT NULL,
          start_date   TEXT    NOT NULL
        )
      ''');


      await db.execute('''
        CREATE TRIGGER no_subtasks_on_fixed
        BEFORE INSERT ON subtasks
        WHEN (SELECT type FROM events WHERE id = NEW.event_id) = 'fixed'
        BEGIN
          SELECT RAISE(ABORT, 'Cannot add subtasks to fixed events');
        END;
      ''');


      await db.execute('''
        CREATE TRIGGER no_subtasks_on_with_start_date
        BEFORE INSERT ON subtasks
        WHEN (SELECT start_date FROM events WHERE id = NEW.event_id) IS NOT NULL
        BEGIN
          SELECT RAISE(ABORT, 'Cannot add subtasks to an event that has a start_date');
        END;
      ''');


      await db.execute('''
        CREATE TRIGGER no_start_date_with_existing_subtasks
        BEFORE UPDATE OF start_date ON events
        WHEN NEW.start_date IS NOT NULL
          AND (SELECT COUNT(*) FROM subtasks WHERE event_id = OLD.id) > 0
        BEGIN
          SELECT RAISE(ABORT, 'Cannot set start_date for events that already have subtasks');
        END;
      ''');
        // Seed sample data
        // final now = DateTime.now();
        // await db.insert('events', {
        //   'name': 'Meeting mit Team',
        //   'category': '@uncategorized',
        //   'start_date': now.subtract(Duration(days: 1)).toIso8601String(),
        //   'deadline':
        //       now
        //           .subtract(Duration(days: 1))
        //           .add(Duration(hours: 1))
        //           .toIso8601String(),
        //   'duration_ms': Duration(hours: 1).inMilliseconds,
        //   'priority': null,
        //   'type': 'base',
        // });
        // await db.insert('events', {
        //   'name': 'Projekt-Deadline',
        //   'category': '@uncategorized',
        //   'start_date': now.add(Duration(days: 2)).toIso8601String(),
        //   'deadline':
        //       now
        //           .add(Duration(days: 2))
        //           .add(Duration(hours: 2))
        //           .toIso8601String(),
        //   'duration_ms': Duration(hours: 2).inMilliseconds,
        //   'priority': null,
        //   'type': 'base',
        // });
        // await db.insert('events', {
        //   'name': 'Arzttermin',
        //   'category': '@uncategorized',
        //   'start_date': now.add(Duration(days: 3)).toIso8601String(),
        //   'deadline':
        //       now
        //           .add(Duration(days: 3))
        //           .add(Duration(minutes: 30))
        //           .toIso8601String(),
        //   'duration_ms': Duration(minutes: 30).inMilliseconds,
        //   'priority': null,
        //   'type': 'base',
        // });
      },
    );
    return _database!;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
