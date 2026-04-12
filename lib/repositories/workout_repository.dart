import '../core/database/database_helper.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/workout.dart';

class WorkoutRepository {
  const WorkoutRepository(this._db);
  final DatabaseHelper _db;

  // ── Workouts ──────────────────────────────────────────────────────────────

  Future<List<Workout>> getByProgram(String programId) async {
    final db = await _db.db;
    final rows = await db.query(
      'workouts',
      where: 'program_id = ?',
      whereArgs: [programId],
      orderBy: 'order_index ASC, created_at ASC',
    );
    return rows.map(Workout.fromMap).toList();
  }

  Future<Workout?> getById(String id) async {
    final db = await _db.db;
    final rows = await db.query('workouts', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Workout.fromMap(rows.first);
  }

  Future<void> insertWorkout(Workout workout) async {
    final db = await _db.db;
    await db.insert('workouts', workout.toMap());
  }

  Future<void> updateWorkout(Workout workout) async {
    final db = await _db.db;
    await db.update('workouts', workout.toMap(), where: 'id = ?', whereArgs: [workout.id]);
  }

  Future<void> deleteWorkout(String id) async {
    final db = await _db.db;
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  // ── Exercises ─────────────────────────────────────────────────────────────

  Future<List<Exercise>> getExercises(String workoutId) async {
    final db = await _db.db;
    final rows = await db.query(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'order_index ASC',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  /// Retourne les exercices avec leurs séries planifiées.
  Future<List<Exercise>> getExercisesWithSets(String workoutId) async {
    final exercises = await getExercises(workoutId);
    final result = <Exercise>[];
    for (final ex in exercises) {
      final sets = await getSets(ex.id);
      result.add(ex.copyWith(sets: sets));
    }
    return result;
  }

  Future<void> insertExercise(Exercise exercise) async {
    final db = await _db.db;
    await db.insert('exercises', exercise.toMap());
  }

  Future<void> updateExercise(Exercise exercise) async {
    final db = await _db.db;
    await db.update('exercises', exercise.toMap(), where: 'id = ?', whereArgs: [exercise.id]);
  }

  Future<void> deleteExercise(String id) async {
    final db = await _db.db;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ── ExerciseSets ──────────────────────────────────────────────────────────

  Future<List<ExerciseSet>> getSets(String exerciseId) async {
    final db = await _db.db;
    final rows = await db.query(
      'exercise_sets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'set_number ASC',
    );
    return rows.map(ExerciseSet.fromMap).toList();
  }

  Future<void> insertSet(ExerciseSet set) async {
    final db = await _db.db;
    await db.insert('exercise_sets', set.toMap());
  }

  Future<void> updateSet(ExerciseSet set) async {
    final db = await _db.db;
    await db.update('exercise_sets', set.toMap(), where: 'id = ?', whereArgs: [set.id]);
  }

  Future<void> deleteSet(String id) async {
    final db = await _db.db;
    await db.delete('exercise_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSetsForExercise(String exerciseId) async {
    final db = await _db.db;
    await db.delete('exercise_sets', where: 'exercise_id = ?', whereArgs: [exerciseId]);
  }
}
