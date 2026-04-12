class WorkoutHistory {
  final String id;
  final String workoutId;
  final String programId;
  final String workoutName;
  final String programName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? notes;
  final List<HistoryExercise> exercises;

  const WorkoutHistory({
    required this.id,
    required this.workoutId,
    required this.programId,
    required this.workoutName,
    required this.programName,
    required this.startedAt,
    this.finishedAt,
    this.notes,
    this.exercises = const [],
  });

  Duration? get duration {
    if (finishedAt == null) return null;
    return finishedAt!.difference(startedAt);
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
  int get completedSets => exercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.completed).length);

  WorkoutHistory copyWith({DateTime? finishedAt, String? notes}) => WorkoutHistory(
        id: id,
        workoutId: workoutId,
        programId: programId,
        workoutName: workoutName,
        programName: programName,
        startedAt: startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        notes: notes ?? this.notes,
        exercises: exercises,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'workout_id': workoutId,
        'program_id': programId,
        'workout_name': workoutName,
        'program_name': programName,
        'started_at': startedAt.millisecondsSinceEpoch,
        'finished_at': finishedAt?.millisecondsSinceEpoch,
        'notes': notes,
      };

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) => WorkoutHistory(
        id: map['id'] as String,
        workoutId: map['workout_id'] as String,
        programId: map['program_id'] as String,
        workoutName: map['workout_name'] as String,
        programName: map['program_name'] as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
        finishedAt: map['finished_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['finished_at'] as int)
            : null,
        notes: map['notes'] as String?,
      );
}

class HistoryExercise {
  final String id;
  final String historyId;
  final String exerciseId;
  final String exerciseName;
  final int orderIndex;
  final List<HistorySet> sets;

  const HistoryExercise({
    required this.id,
    required this.historyId,
    required this.exerciseId,
    required this.exerciseName,
    required this.orderIndex,
    this.sets = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'history_id': historyId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'order_index': orderIndex,
      };

  factory HistoryExercise.fromMap(Map<String, dynamic> map) => HistoryExercise(
        id: map['id'] as String,
        historyId: map['history_id'] as String,
        exerciseId: map['exercise_id'] as String,
        exerciseName: map['exercise_name'] as String,
        orderIndex: map['order_index'] as int,
      );
}

class HistorySet {
  final String id;
  final String historyExerciseId;
  final int setNumber;
  final int? plannedReps;
  final double? plannedWeight;
  final int? actualReps;
  final double? actualWeight;
  final int? durationSeconds;
  final int? restSeconds;
  final String? notes;
  final bool completed;

  const HistorySet({
    required this.id,
    required this.historyExerciseId,
    required this.setNumber,
    this.plannedReps,
    this.plannedWeight,
    this.actualReps,
    this.actualWeight,
    this.durationSeconds,
    this.restSeconds,
    this.notes,
    required this.completed,
  });

  HistorySet copyWith({
    int? actualReps,
    double? actualWeight,
    bool? completed,
    String? notes,
  }) =>
      HistorySet(
        id: id,
        historyExerciseId: historyExerciseId,
        setNumber: setNumber,
        plannedReps: plannedReps,
        plannedWeight: plannedWeight,
        actualReps: actualReps ?? this.actualReps,
        actualWeight: actualWeight ?? this.actualWeight,
        durationSeconds: durationSeconds,
        restSeconds: restSeconds,
        notes: notes ?? this.notes,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'history_exercise_id': historyExerciseId,
        'set_number': setNumber,
        'planned_reps': plannedReps,
        'planned_weight': plannedWeight,
        'actual_reps': actualReps,
        'actual_weight': actualWeight,
        'duration_seconds': durationSeconds,
        'rest_seconds': restSeconds,
        'notes': notes,
        'completed': completed ? 1 : 0,
      };

  factory HistorySet.fromMap(Map<String, dynamic> map) => HistorySet(
        id: map['id'] as String,
        historyExerciseId: map['history_exercise_id'] as String,
        setNumber: map['set_number'] as int,
        plannedReps: map['planned_reps'] as int?,
        plannedWeight: (map['planned_weight'] as num?)?.toDouble(),
        actualReps: map['actual_reps'] as int?,
        actualWeight: (map['actual_weight'] as num?)?.toDouble(),
        durationSeconds: map['duration_seconds'] as int?,
        restSeconds: map['rest_seconds'] as int?,
        notes: map['notes'] as String?,
        completed: (map['completed'] as int) == 1,
      );
}
