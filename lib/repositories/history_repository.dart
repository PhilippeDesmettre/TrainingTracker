import '../core/database/database_helper.dart';
import '../models/workout_history.dart';

class HistoryRepository {
  const HistoryRepository(this._db);
  final DatabaseHelper _db;

  Future<List<WorkoutHistory>> getAll({int limit = 50}) async {
    final db = await _db.db;
    final rows = await db.query(
      'workout_history',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    final histories = <WorkoutHistory>[];
    for (final row in rows) {
      final history = WorkoutHistory.fromMap(row);
      final exercises = await _getExercisesForHistory(history.id);
      histories.add(history.copyWith());
      // On reconstruit avec les exercices
      histories[histories.length - 1] = WorkoutHistory(
        id: history.id,
        workoutId: history.workoutId,
        programId: history.programId,
        workoutName: history.workoutName,
        programName: history.programName,
        startedAt: history.startedAt,
        finishedAt: history.finishedAt,
        notes: history.notes,
        exercises: exercises,
      );
    }
    return histories;
  }

  Future<WorkoutHistory?> getById(String id) async {
    final db = await _db.db;
    final rows = await db.query('workout_history', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final history = WorkoutHistory.fromMap(rows.first);
    final exercises = await _getExercisesForHistory(id);
    return WorkoutHistory(
      id: history.id,
      workoutId: history.workoutId,
      programId: history.programId,
      workoutName: history.workoutName,
      programName: history.programName,
      startedAt: history.startedAt,
      finishedAt: history.finishedAt,
      notes: history.notes,
      exercises: exercises,
    );
  }

  Future<void> createHistory(WorkoutHistory history) async {
    final db = await _db.db;
    await db.insert('workout_history', history.toMap());
  }

  Future<void> finishHistory(String id, DateTime finishedAt) async {
    final db = await _db.db;
    await db.update(
      'workout_history',
      {'finished_at': finishedAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteHistory(String id) async {
    final db = await _db.db;
    await db.delete('workout_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> createHistoryExercise(HistoryExercise exercise) async {
    final db = await _db.db;
    await db.insert('history_exercises', exercise.toMap());
  }

  Future<void> createHistorySet(HistorySet set) async {
    final db = await _db.db;
    await db.insert('history_sets', set.toMap());
  }

  Future<void> updateHistorySet(
    String id, {
    int? actualReps,
    double? actualWeight,
    required bool completed,
  }) async {
    final db = await _db.db;
    await db.update(
      'history_sets',
      {
        'actual_reps': actualReps,
        'actual_weight': actualWeight,
        'completed': completed ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<HistoryExercise>> _getExercisesForHistory(String historyId) async {
    final db = await _db.db;
    final rows = await db.query(
      'history_exercises',
      where: 'history_id = ?',
      whereArgs: [historyId],
      orderBy: 'order_index ASC',
    );
    final exercises = <HistoryExercise>[];
    for (final row in rows) {
      final exercise = HistoryExercise.fromMap(row);
      final setRows = await db.query(
        'history_sets',
        where: 'history_exercise_id = ?',
        whereArgs: [exercise.id],
        orderBy: 'set_number ASC',
      );
      final sets = setRows.map(HistorySet.fromMap).toList();
      exercises.add(HistoryExercise(
        id: exercise.id,
        historyId: exercise.historyId,
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        orderIndex: exercise.orderIndex,
        sets: sets,
      ));
    }
    return exercises;
  }

  /// Stats globales pour l'écran statistiques.
  Future<Map<String, dynamic>> getStats() async {
    final db = await _db.db;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM workout_history WHERE finished_at IS NOT NULL',
    );
    final totalSessions = (totalResult.first['count'] as int?) ?? 0;

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM workout_history WHERE finished_at IS NOT NULL AND started_at > ?',
      [weekAgo.millisecondsSinceEpoch],
    );
    final thisWeekSessions = (weekResult.first['count'] as int?) ?? 0;

    final volumeResult = await db.rawQuery(
      'SELECT SUM(actual_weight * actual_reps) as volume FROM history_sets WHERE completed = 1',
    );
    final totalVolume = (volumeResult.first['volume'] as num?)?.toDouble() ?? 0.0;

    return {
      'total_sessions': totalSessions,
      'this_week_sessions': thisWeekSessions,
      'total_volume_kg': totalVolume,
    };
  }
}
