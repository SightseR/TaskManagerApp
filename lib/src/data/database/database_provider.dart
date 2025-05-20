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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            start TEXT,
            end TEXT
          )
        ''');
        final now = DateTime.now();
        await db.insert('events', {
          'title': 'Meeting mit Team',
          'start': now.subtract(Duration(days: 1)).toIso8601String(),
          'end': now.subtract(Duration(days: 1)).add(Duration(hours: 1)).toIso8601String(),
        });
        await db.insert('events', {
          'title': 'Projekt-Deadline',
          'start': now.add(Duration(days: 2)).toIso8601String(),
          'end': now.add(Duration(days: 2)).add(Duration(hours: 2)).toIso8601String(),
        });
        await db.insert('events', {
          'title': 'Arzttermin',
          'start': now.add(Duration(days: 3)).toIso8601String(),
          'end': now.add(Duration(days: 3)).add(Duration(minutes: 30)).toIso8601String(),
        });
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
