import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'training_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE programs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        program_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        name TEXT NOT NULL,
        muscle_group TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_sets (
        id TEXT PRIMARY KEY,
        exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER,
        weight REAL,
        duration_seconds INTEGER,
        rest_seconds INTEGER,
        notes TEXT,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_history (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        program_id TEXT NOT NULL,
        workout_name TEXT NOT NULL,
        program_name TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        finished_at INTEGER,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE history_exercises (
        id TEXT PRIMARY KEY,
        history_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (history_id) REFERENCES workout_history(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE history_sets (
        id TEXT PRIMARY KEY,
        history_exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        planned_reps INTEGER,
        planned_weight REAL,
        actual_reps INTEGER,
        actual_weight REAL,
        duration_seconds INTEGER,
        rest_seconds INTEGER,
        notes TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (history_exercise_id) REFERENCES history_exercises(id) ON DELETE CASCADE
      )
    ''');
  }
}
